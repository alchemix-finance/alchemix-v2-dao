// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "lib/forge-std/src/console2.sol";

import "src/interfaces/IBribeFactory.sol";
import "src/interfaces/IBribe.sol";
import "src/interfaces/IBaseGauge.sol";
import "src/interfaces/IGaugeFactory.sol";
import "src/interfaces/IMinter.sol";
import "src/interfaces/IVotingEscrow.sol";
import "src/interfaces/IVoter.sol";
import "src/interfaces/IManaToken.sol";
import "src/libraries/Math.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title Voter
 * @notice Voting contract to handle veALCX gauge voting
 */
contract Voter is IVoter {
    address internal immutable base; // Base token, ALCX

    address public immutable veALCX; // veALCX that governs these contracts
    address public immutable MANA; // veALCX that governs these contracts
    address public immutable gaugefactory;
    address public immutable bribefactory;

    uint256 internal constant BPS = 10000;
    uint256 internal constant DURATION = 7 days; // rewards are released over 7 days
    uint256 internal constant BRIBE_LAG = 1 days;
    uint256 internal index;

    address public minter;
    address public executor; // should be set to the timelock executor
    address public pendingExecutor;
    address public emergencyCouncil; // credibly neutral party similar to Curve's Emergency DAO

    uint256 public totalWeight; // total voting weight
    uint256 public boostMultiplier = 5000; // max bps veALCX voting power can be boosted by

    address[] public pools; // all pools viable for incentives

    mapping(address => address) public gauges; // pool => gauge
    mapping(address => address) public poolForGauge; // gauge => pool
    mapping(address => address) public bribes; // gauge => bribe
    mapping(address => uint256) public weights; // pool => weight
    mapping(uint256 => mapping(address => uint256)) public votes; // token => pool => votes
    mapping(uint256 => address[]) public poolVote; // token => pools
    mapping(uint256 => uint256) public usedWeights; // token => total voting weight of user
    mapping(uint256 => uint256) public lastVoted; // token => timestamp of last vote, to ensure one vote per epoch
    mapping(address => bool) public isGauge;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isAlive;
    mapping(address => uint256) internal supplyIndex;
    mapping(address => uint256) public claimable;

    constructor(address _ve, address _gauges, address _bribes, address _mana) {
        veALCX = _ve;
        MANA = _mana;
        base = IVotingEscrow(_ve).ALCX();
        gaugefactory = _gauges;
        bribefactory = _bribes;
        minter = msg.sender;
        executor = msg.sender;
        emergencyCouncil = msg.sender;
    }

    /*
        Modifiers
    */

    // Re-entrancy check
    uint256 internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    modifier onlyNewEpoch(uint256 _tokenId) {
        // Ensure new epoch since last vote
        require((block.timestamp / DURATION) * DURATION > lastVoted[_tokenId], "TOKEN_ALREADY_VOTED_THIS_EPOCH");
        _;
    }

    /*
        View functions
    */

    /// @inheritdoc IVoter
    function maxVotingPower(uint256 _tokenId) public view returns (uint256) {
        return
            IVotingEscrow(veALCX).balanceOfToken(_tokenId) +
            ((IVotingEscrow(veALCX).balanceOfToken(_tokenId) * boostMultiplier) / BPS);
    }

    /// @inheritdoc IVoter
    function maxManaBoost(uint256 _tokenId) public view returns (uint256) {
        return (IVotingEscrow(veALCX).balanceOfToken(_tokenId) * boostMultiplier) / BPS;
    }

    function length() external view returns (uint256) {
        return pools.length;
    }

    /*
        External functions
    */

    function initialize(address _token, address _minter) external {
        require(msg.sender == minter);
        _whitelist(_token);
        minter = _minter;
    }

    function setExecutor(address _executor) external {
        require(msg.sender == executor, "not executor");
        pendingExecutor = _executor;
    }

    function acceptExecutor() external {
        require(msg.sender == pendingExecutor, "not pending executor");
        executor = pendingExecutor;
    }

    function setEmergencyCouncil(address _council) public {
        require(msg.sender == emergencyCouncil);
        emergencyCouncil = _council;
    }

    /// @inheritdoc IVoter
    function setBoostMultiplier(uint256 _boostMultiplier) external {
        require(msg.sender == executor, "not executor");
        boostMultiplier = _boostMultiplier;
    }

    /// @inheritdoc IVoter
    function reset(uint256 _tokenId) external onlyNewEpoch(_tokenId) {
        require(IVotingEscrow(veALCX).isApprovedOrOwner(msg.sender, _tokenId), "not approved or owner");

        lastVoted[_tokenId] = block.timestamp;
        _reset(_tokenId);
        IVotingEscrow(veALCX).abstain(_tokenId);
        IVotingEscrow(veALCX).accrueMana(_tokenId, IVotingEscrow(veALCX).claimableMana(_tokenId));
    }

    function _reset(uint256 _tokenId) internal {
        address[] storage _poolVote = poolVote[_tokenId];
        uint256 _poolVoteCnt = _poolVote.length;
        uint256 _totalWeight = 0;

        for (uint256 i = 0; i < _poolVoteCnt; i++) {
            address _pool = _poolVote[i];
            uint256 _votes = votes[_tokenId][_pool];

            if (_votes != 0) {
                _updateFor(gauges[_pool]);
                weights[_pool] -= _votes;
                votes[_tokenId][_pool] -= _votes;
                if (_votes > 0) {
                    _totalWeight += _votes;
                }
                emit Abstained(_tokenId, _votes);
            }
        }
        totalWeight -= uint256(_totalWeight);
        usedWeights[_tokenId] = 0;
        delete poolVote[_tokenId];
    }

    /// @inheritdoc IVoter
    function poke(uint256 _tokenId, uint256 _boost) external {
        require(IVotingEscrow(veALCX).claimableMana(_tokenId) >= _boost, "insufficient claimable MANA balance");

        address[] memory _poolVote = poolVote[_tokenId];
        uint256 _poolCnt = _poolVote.length;
        uint256[] memory _weights = new uint256[](_poolCnt);

        for (uint256 i = 0; i < _poolCnt; i++) {
            _weights[i] = votes[_tokenId][_poolVote[i]];
        }

        _vote(_tokenId, _poolVote, _weights, _boost);
    }

    /// @inheritdoc IVoter
    function vote(
        uint256 _tokenId,
        address[] calldata _poolVote,
        uint256[] calldata _weights,
        uint256 _boost
    ) external onlyNewEpoch(_tokenId) {
        require(IVotingEscrow(veALCX).isApprovedOrOwner(msg.sender, _tokenId));
        require(_poolVote.length == _weights.length);
        require(IVotingEscrow(veALCX).claimableMana(_tokenId) >= _boost, "insufficient claimable MANA balance");
        require(
            (IVotingEscrow(veALCX).balanceOfToken(_tokenId) + _boost) <= maxVotingPower(_tokenId),
            "cannot exceed max boost"
        );

        lastVoted[_tokenId] = block.timestamp;
        _vote(_tokenId, _poolVote, _weights, _boost);
    }

    function whitelist(address _token) public {
        require(msg.sender == executor, "not executor");
        _whitelist(_token);
    }

    /// @inheritdoc IVoter
    function createGauge(address _pool, GaugeType _gaugeType) external returns (address) {
        require(gauges[_pool] == address(0x0), "exists");
        require(msg.sender == executor, "only executor creates gauges");

        address _bribe = IBribeFactory(bribefactory).createBribe();

        // Handle gauge type
        address _gauge;

        if (_gaugeType == IVoter.GaugeType.Staking) {
            _gauge = IGaugeFactory(gaugefactory).createStakingGauge(_pool, _bribe, veALCX);
        }
        if (_gaugeType == IVoter.GaugeType.Curve) {
            _gauge = IGaugeFactory(gaugefactory).createCurveGauge(_bribe, veALCX);
        }
        if (_gaugeType == IVoter.GaugeType.Passthrough) {
            _gauge = IGaugeFactory(gaugefactory).createPassthroughGauge(_pool, _bribe, veALCX);
        }

        IERC20(base).approve(_gauge, type(uint256).max);
        bribes[_gauge] = _bribe;
        gauges[_pool] = _gauge;
        poolForGauge[_gauge] = _pool;
        isGauge[_gauge] = true;
        isAlive[_gauge] = true;
        _updateFor(_gauge);
        pools.push(_pool);
        emit GaugeCreated(_gauge, msg.sender, _bribe, _pool);
        return _gauge;
    }

    function killGauge(address _gauge) external {
        require(msg.sender == emergencyCouncil, "not emergency council");
        require(isAlive[_gauge], "gauge already dead");
        isAlive[_gauge] = false;
        emit GaugeKilled(_gauge);
    }

    function reviveGauge(address _gauge) external {
        require(msg.sender == emergencyCouncil, "not emergency council");
        require(!isAlive[_gauge], "gauge already alive");
        isAlive[_gauge] = true;
        emit GaugeRevived(_gauge);
    }

    /// @inheritdoc IVoter
    function attachTokenToGauge(uint256 tokenId, address account) external {
        require(isGauge[msg.sender]);
        require(isAlive[msg.sender]); // killed gauges cannot attach tokens to themselves
        if (tokenId > 0) IVotingEscrow(veALCX).attach(tokenId);
        emit Attach(account, msg.sender, tokenId);
    }

    /// @inheritdoc IVoter
    function detachTokenFromGauge(uint256 tokenId, address account) external {
        require(isGauge[msg.sender]);
        if (tokenId > 0) IVotingEscrow(veALCX).detach(tokenId);
        emit Detach(account, msg.sender, tokenId);
    }

    /// @inheritdoc IVoter
    function notifyRewardAmount(uint256 amount) external {
        _safeTransferFrom(base, msg.sender, address(this), amount); // transfer the distro in

        // Handle case if totalWeight is 0
        uint256 _ratio = totalWeight > 0 ? (amount * 1e18) / totalWeight : (amount * 1e18); // 1e18 adjustment is removed during claim
        if (_ratio > 0) {
            index += _ratio;
        }
        emit NotifyReward(msg.sender, base, amount);
    }

    function updateFor(address[] memory _gauges) external {
        for (uint256 i = 0; i < _gauges.length; i++) {
            _updateFor(_gauges[i]);
        }
    }

    function updateForRange(uint256 start, uint256 end) public {
        for (uint256 i = start; i < end; i++) {
            _updateFor(gauges[pools[i]]);
        }
    }

    function updateAll() external {
        updateForRange(0, pools.length);
    }

    function updateGauge(address _gauge) external {
        _updateFor(_gauge);
    }

    function claimRewards(address[] memory _gauges, address[][] memory _tokens) external {
        for (uint256 i = 0; i < _gauges.length; i++) {
            IBaseGauge(_gauges[i]).getReward(msg.sender, _tokens[i]);
        }
    }

    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint256 _tokenId) external {
        require(IVotingEscrow(veALCX).isApprovedOrOwner(msg.sender, _tokenId));
        for (uint256 i = 0; i < _bribes.length; i++) {
            IBribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
        }
    }

    /// @inheritdoc IVoter
    function distribute(address _gauge) public lock {
        IMinter(minter).updatePeriod();
        _updateFor(_gauge);
        uint256 _claimable = claimable[_gauge];
        if (_claimable > IBaseGauge(_gauge).left(base) && _claimable / DURATION > 0) {
            claimable[_gauge] = 0;
            IBaseGauge(_gauge).notifyRewardAmount(base, _claimable);
            emit DistributeReward(msg.sender, _gauge, _claimable);
        }
    }

    function distro() external {
        distribute(0, pools.length);
    }

    function distribute() external {
        distribute(0, pools.length);
    }

    function distribute(uint256 start, uint256 finish) public {
        for (uint256 x = start; x < finish; x++) {
            distribute(gauges[pools[x]]);
        }
    }

    function distribute(address[] memory _gauges) external {
        for (uint256 x = 0; x < _gauges.length; x++) {
            distribute(_gauges[x]);
        }
    }

    /*
        Internal functions
    */

    function _vote(uint256 _tokenId, address[] memory _poolVote, uint256[] memory _weights, uint256 _boost) internal {
        _reset(_tokenId);

        uint256 _poolCnt = _poolVote.length;
        uint256 _totalVoteWeight = 0;
        uint256 _totalWeight = 0;
        uint256 _usedWeight = 0;

        for (uint256 i = 0; i < _poolCnt; i++) {
            _totalVoteWeight += _weights[i];
        }

        for (uint256 i = 0; i < _poolCnt; i++) {
            address _pool = _poolVote[i];
            address _gauge = gauges[_pool];

            if (isGauge[_gauge]) {
                uint256 _poolWeight = (_weights[i] * (IVotingEscrow(veALCX).balanceOfToken(_tokenId) + _boost)) /
                    _totalVoteWeight;
                require(votes[_tokenId][_pool] == 0);
                require(_poolWeight != 0);
                _updateFor(_gauge);

                poolVote[_tokenId].push(_pool);

                weights[_pool] += _poolWeight;
                votes[_tokenId][_pool] += _poolWeight;
                IBribe(bribes[_gauge]).deposit(uint256(_poolWeight), _tokenId);
                _usedWeight += _poolWeight;
                _totalWeight += _poolWeight;
                emit Voted(msg.sender, _tokenId, _poolWeight);
            }
        }
        if (_usedWeight > 0) IVotingEscrow(veALCX).voting(_tokenId);
        totalWeight += uint256(_totalWeight);
        usedWeights[_tokenId] = uint256(_usedWeight);

        // Accrue any mana not used for vote boost
        if (IVotingEscrow(veALCX).claimableMana(_tokenId) > _boost)
            IVotingEscrow(veALCX).accrueMana(_tokenId, IVotingEscrow(veALCX).claimableMana(_tokenId) - _boost);
    }

    function _whitelist(address _token) internal {
        require(!isWhitelisted[_token]);
        isWhitelisted[_token] = true;
        emit Whitelisted(msg.sender, _token);
    }

    function _updateFor(address _gauge) internal {
        address _pool = poolForGauge[_gauge];
        uint256 _supplied = weights[_pool];
        if (_supplied > 0) {
            uint256 _supplyIndex = supplyIndex[_gauge];
            uint256 _index = index; // get global index0 for accumulated distro
            supplyIndex[_gauge] = _index; // update _gauge current position to global position
            uint256 _delta = _index - _supplyIndex; // see if there is any difference that need to be accrued
            if (_delta > 0) {
                uint256 _share = (uint256(_supplied) * _delta) / 1e18; // add accrued difference for each supplied token
                claimable[_gauge] += _share;
            }
        } else {
            supplyIndex[_gauge] = index; // new users are set to the default global state
        }
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}
