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
import "src/interfaces/IFluxToken.sol";
import "src/libraries/Math.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title Voter
 * @notice Voting contract to handle veALCX gauge voting
 */
contract Voter is IVoter {
    address internal immutable base; // Base token, ALCX

    address public immutable veALCX;
    /// @notice FLUX contract address
    address public immutable FLUX;
    /// @notice Gauge factory contract address
    address public immutable gaugefactory;
    /// @notice Bribe factory contract address
    address public immutable bribefactory;

    uint256 internal constant BPS = 10_000;
    uint256 internal constant MAX_BOOST = 10_000;
    uint256 internal constant MIN_BOOST = 0;
    /// @notice Rewards are released over this duration (2 weeks)
    uint256 internal constant DURATION = 2 weeks;
    uint256 internal constant BRIBE_LAG = 1 days;
    uint256 internal index;

    /// @notice Minter contract address
    address public minter;
    address public admin; // should be set to the timelock admin
    address public pendingAdmin;
    /// @notice Address of credibly neutral party similar to Curve's Emergency DAO
    address public emergencyCouncil;

    /// @notice Total voting weight
    uint256 public totalWeight;
    /// @notice Max bps veALCX voting power can be boosted by
    uint256 public boostMultiplier = 10000;

    /// @notice All pools viable for incentives
    address[] public pools;

    /// @notice pool => gauge
    mapping(address => address) public gauges;
    /// @notice gauge => pool
    mapping(address => address) public poolForGauge;
    /// @notice gauge => bribe
    mapping(address => address) public bribes;
    /// @notice pool => weight
    mapping(address => uint256) public weights;
    /// @notice token => pool => votes
    mapping(uint256 => mapping(address => uint256)) public votes;
    /// @notice token => pools
    mapping(uint256 => address[]) public poolVote;
    /// @notice token => total voting weight of user
    mapping(uint256 => uint256) public usedWeights;
    /// @notice token => timestamp of last vote, to ensure one vote per epoch
    mapping(uint256 => uint256) public lastVoted;
    /// @notice return if address is a gauge
    mapping(address => bool) public isGauge;
    /// @notice return if address is whitelisted
    mapping(address => bool) public isWhitelisted;
    /// @notice return if gauge is alive
    mapping(address => bool) public isAlive;
    /// @notice return the supply index of a gauge
    mapping(address => uint256) internal supplyIndex;
    /// @notice reutrn the claimable amount for a gauge
    mapping(address => uint256) public claimable;

    constructor(address _ve, address _gauges, address _bribes, address _flux, address _token) {
        veALCX = _ve;
        FLUX = _flux;
        base = IVotingEscrow(_ve).ALCX();
        gaugefactory = _gauges;
        bribefactory = _bribes;
        minter = msg.sender;
        admin = msg.sender;
        emergencyCouncil = msg.sender;
        _whitelist(_token);
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
        uint256 balance = IVotingEscrow(veALCX).balanceOfToken(_tokenId);

        return balance + ((balance * boostMultiplier) / BPS);
    }

    /// @inheritdoc IVoter
    function maxFluxBoost(uint256 _tokenId) external view returns (uint256) {
        return (IVotingEscrow(veALCX).balanceOfToken(_tokenId) * boostMultiplier) / BPS;
    }

    /// @inheritdoc IVoter
    function length() external view returns (uint256) {
        return pools.length;
    }

    /// @inheritdoc IVoter
    function getPoolVote(uint256 _tokenId) external view returns (address[] memory) {
        return poolVote[_tokenId];
    }

    /*
        External functions
    */

    /// @inheritdoc IVoter
    function setMinter(address _minter) external {
        require(msg.sender == admin, "not admin");
        require(_minter != address(0), "FluxToken: minter cannot be zero address");
        minter = _minter;
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "not admin");
        pendingAdmin = _admin;
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "not pending admin");
        admin = pendingAdmin;

        emit AdminUpdated(pendingAdmin);
    }

    /// @inheritdoc IVoter
    function setEmergencyCouncil(address _council) public {
        require(msg.sender == emergencyCouncil, "not emergency council");
        require(_council != address(0), "cannot be zero address");
        emergencyCouncil = _council;
        emit EmergencyCouncilUpdated(_council);
    }

    /// @inheritdoc IVoter
    function swapReward(address gaugeAddress, uint256 tokenIndex, address oldToken, address newToken) external {
        require(msg.sender == admin, "only admin can swap reward tokens");
        IBribe(bribes[gaugeAddress]).swapOutRewardToken(tokenIndex, oldToken, newToken);
    }

    /// @inheritdoc IVoter
    function setBoostMultiplier(uint256 _boostMultiplier) external {
        require(msg.sender == admin, "not admin");
        require(_boostMultiplier <= MAX_BOOST && _boostMultiplier > MIN_BOOST, "Boost multiplier is out of bounds");
        boostMultiplier = _boostMultiplier;
        emit SetBoostMultiplier(_boostMultiplier);
    }

    /// @inheritdoc IVoter
    function reset(uint256 _tokenId) public onlyNewEpoch(_tokenId) {
        if (msg.sender != admin) {
            require(IVotingEscrow(veALCX).isApprovedOrOwner(msg.sender, _tokenId), "not approved or owner");
        }

        lastVoted[_tokenId] = block.timestamp;
        _reset(_tokenId);
        IVotingEscrow(veALCX).abstain(_tokenId);
        IFluxToken(FLUX).accrueFlux(_tokenId);
    }

    /// @inheritdoc IVoter
    function poke(uint256 _tokenId) public {
        // Previous boost will be taken into account with weights being pulled from the votes mapping
        uint256 _boost = 0;

        if (msg.sender != admin) {
            require(IVotingEscrow(veALCX).isApprovedOrOwner(msg.sender, _tokenId), "not approved or owner");
        }

        address[] memory _poolVote = poolVote[_tokenId];
        uint256 _poolCnt = _poolVote.length;
        uint256[] memory _weights = new uint256[](_poolCnt);

        for (uint256 i = 0; i < _poolCnt; i++) {
            _weights[i] = votes[_tokenId][_poolVote[i]];
        }

        _vote(_tokenId, _poolVote, _weights, _boost);
    }

    /// @inheritdoc IVoter
    function pokeTokens(uint256[] memory _tokenIds) external {
        require(msg.sender == admin, "not admin");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            // If the token has expired, reset it
            if (block.timestamp > IVotingEscrow(veALCX).lockEnd(_tokenId)) {
                reset(_tokenId);
            }
            poke(_tokenId);
        }
    }

    /// @inheritdoc IVoter
    function vote(
        uint256 _tokenId,
        address[] calldata _poolVote,
        uint256[] calldata _weights,
        uint256 _boost
    ) external onlyNewEpoch(_tokenId) {
        require(IVotingEscrow(veALCX).isApprovedOrOwner(msg.sender, _tokenId), "not approved or owner");
        require(_poolVote.length == _weights.length, "pool vote and weights mismatch");
        require(_poolVote.length > 0, "no pools voted for");
        require(_poolVote.length <= pools.length, "invalid pools");
        require(
            IVotingEscrow(veALCX).claimableFlux(_tokenId) + IFluxToken(FLUX).getUnclaimedFlux(_tokenId) >= _boost,
            "insufficient FLUX to boost"
        );
        require(
            (IVotingEscrow(veALCX).balanceOfToken(_tokenId) + _boost) <= maxVotingPower(_tokenId),
            "cannot exceed max boost"
        );
        require(block.timestamp < IVotingEscrow(veALCX).lockEnd(_tokenId), "cannot vote with expired token");

        if (block.timestamp >= IMinter(minter).activePeriod() + 2 weeks) {
            IMinter(minter).updatePeriod();
        }

        _vote(_tokenId, _poolVote, _weights, _boost);
    }

    /// @inheritdoc IVoter
    function whitelist(address _token) public {
        require(msg.sender == admin, "not admin");
        require(_token != address(0), "cannot be zero address");
        _whitelist(_token);
    }

    /// @inheritdoc IVoter
    function removeFromWhitelist(address _token) external {
        require(msg.sender == admin, "not admin");
        _removeFromWhitelist(_token);
    }

    /// @inheritdoc IVoter
    function createGauge(address _pool, GaugeType _gaugeType) external returns (address) {
        require(msg.sender == admin, "not admin");
        require(gauges[_pool] == address(0x0), "exists");

        address _bribe = IBribeFactory(bribefactory).createBribe();

        // Handle gauge type
        address _gauge;

        if (_gaugeType == IVoter.GaugeType.Curve) {
            _gauge = IGaugeFactory(gaugefactory).createCurveGauge(_bribe, veALCX);
        } else {
            // _gaugeType == IVoter.GaugeType.Passthrough
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
        require(isGauge[_gauge], "invalid gauge");
        require(!isAlive[_gauge], "gauge already alive");
        isAlive[_gauge] = true;
        emit GaugeRevived(_gauge);
    }

    /// @inheritdoc IVoter
    function notifyRewardAmount(uint256 amount) external {
        require(msg.sender == minter, "only minter can send rewards");
        require(totalWeight > 0, "no votes");

        _safeTransferFrom(base, msg.sender, address(this), amount); // transfer rewards in

        uint256 _ratio = (amount * 1e18) / totalWeight; // 1e18 adjustment is removed during claim

        if (_ratio > 0) {
            index += _ratio;
        }

        emit NotifyReward(msg.sender, base, amount);
    }

    /// @inheritdoc IVoter
    function updateFor(address[] memory _gauges) external {
        for (uint256 i = 0; i < _gauges.length; i++) {
            _updateFor(_gauges[i]);
        }
    }

    /// @inheritdoc IVoter
    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint256 _tokenId) external {
        require(IVotingEscrow(veALCX).isApprovedOrOwner(msg.sender, _tokenId));

        for (uint256 i = 0; i < _bribes.length; i++) {
            IBribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
        }
    }

    /// @inheritdoc IVoter
    function distribute() external {
        uint256 start = 0;
        uint256 finish = pools.length;

        for (uint256 x = start; x < finish; x++) {
            // We don't revert if gauge is not alive since pools.length is not reduced
            if (isAlive[gauges[pools[x]]]) {
                _distribute(gauges[pools[x]]);
            }
        }

        IMinter(minter).updatePeriod();
    }

    /*
        Internal functions
    */

    function _distribute(address _gauge) internal {
        // Distribute once after epoch has ended
        require(
            block.timestamp >= IMinter(minter).activePeriod() + IMinter(minter).DURATION(),
            "can only distribute after period end"
        );

        uint256 _claimable = claimable[_gauge];

        // Reset claimable amount
        claimable[_gauge] = 0;

        _updateFor(_gauge);

        if (_claimable > 0) {
            IBaseGauge(_gauge).notifyRewardAmount(_claimable);
        }

        IBribe(bribes[_gauge]).resetVoting();

        emit DistributeReward(msg.sender, _gauge, _claimable);
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

                IBribe(bribes[gauges[_pool]]).withdraw(uint256(_votes), _tokenId);
                _totalWeight += _votes;

                emit Abstained(msg.sender, _pool, _tokenId, _votes);
            }
        }
        totalWeight -= uint256(_totalWeight);
        usedWeights[_tokenId] = 0;
        delete poolVote[_tokenId];

        // Update lock end if max locked
        if (IVotingEscrow(veALCX).isMaxLocked(_tokenId)) {
            IVotingEscrow(veALCX).updateLock(_tokenId);
        }
    }

    function _vote(uint256 _tokenId, address[] memory _poolVote, uint256[] memory _weights, uint256 _boost) internal {
        _reset(_tokenId);

        uint256 _poolCnt = _poolVote.length;
        uint256 _totalVoteWeight = 0;
        uint256 _totalWeight = 0;

        for (uint256 i = 0; i < _poolCnt; i++) {
            _totalVoteWeight += _weights[i];
        }

        IFluxToken(FLUX).accrueFlux(_tokenId);
        uint256 totalPower = (IVotingEscrow(veALCX).balanceOfToken(_tokenId) + _boost);

        for (uint256 i = 0; i < _poolCnt; i++) {
            address _pool = _poolVote[i];
            address _gauge = gauges[_pool];

            require(isAlive[_gauge], "cannot vote for dead gauge");

            uint256 _poolWeight = (_weights[i] * totalPower) / _totalVoteWeight;
            require(votes[_tokenId][_pool] == 0, "already voted for pool");
            require(_poolWeight != 0, "cannot vote with zero weight");
            _updateFor(_gauge);

            poolVote[_tokenId].push(_pool);

            weights[_pool] += _poolWeight;
            votes[_tokenId][_pool] += _poolWeight;
            IBribe(bribes[_gauge]).deposit(uint256(_poolWeight), _tokenId);
            _totalWeight += _poolWeight;
            emit Voted(msg.sender, _pool, _tokenId, _poolWeight);
        }

        if (_totalWeight > 0) IVotingEscrow(veALCX).voting(_tokenId);
        totalWeight += uint256(_totalWeight);
        usedWeights[_tokenId] = uint256(_totalWeight);
        lastVoted[_tokenId] = block.timestamp;

        // Update flux balance of token if boost was used
        if (_boost > 0) {
            IFluxToken(FLUX).updateFlux(_tokenId, _boost);
        }
    }

    function _whitelist(address _token) internal {
        require(!isWhitelisted[_token], "token already whitelisted");
        isWhitelisted[_token] = true;
        emit Whitelisted(msg.sender, _token);
    }

    function _removeFromWhitelist(address _token) internal {
        require(isWhitelisted[_token], "token not whitelisted");
        isWhitelisted[_token] = false;
        emit RemovedFromWhitelist(msg.sender, _token);
    }

    function _updateFor(address _gauge) internal {
        require(isGauge[_gauge], "invalid gauge");

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
            supplyIndex[_gauge] = index;
        }
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}
