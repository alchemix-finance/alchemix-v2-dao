// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./libraries/Math.sol";
import "./interfaces/IBribeFactory.sol";
import "./interfaces/IBaseGauge.sol";
import "./interfaces/IGaugeFactory.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IVotingEscrow.sol";
import { IERC20Mintable } from "./interfaces/IERC20Mintable.sol";

contract Voter {
    address public immutable veALCX; // veALCX that governs these contracts
    address public immutable MANA; // veALCX that governs these contracts
    address internal immutable base;
    address public immutable gaugefactory;
    address public immutable bribefactory;
    uint256 internal constant DURATION = 7 days; // rewards are released over 7 days
    uint256 internal constant BRIBE_LAG = 1 days;
    address public minter;
    address public executor; // should be set to the timelock executor
    address public emergencyCouncil; // credibly neutral party similar to Curve's Emergency DAO

    uint256 public totalWeight; // total voting weight

    // Type of gauge being created
    enum GaugeType {
        Staking,
        Passthrough
    }

    address[] public pools; // all pools viable for incentives
    mapping(address => address) public gauges; // pool => gauge
    mapping(address => address) public poolForGauge; // gauge => pool
    mapping(address => address) public bribes; // gauge => bribe
    mapping(address => uint256) public weights; // pool => weight
    mapping(uint256 => mapping(address => uint256)) public votes; // nft => pool => votes
    mapping(uint256 => address[]) public poolVote; // nft => pools
    mapping(uint256 => uint256) public usedWeights; // nft => total voting weight of user
    mapping(uint256 => uint256) public lastVoted; // nft => timestamp of last vote, to ensure one vote per epoch
    mapping(address => bool) public isGauge;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isAlive;

    event GaugeCreated(address indexed gauge, address creator, address indexed bribe, address indexed pool);
    event GaugeKilled(address indexed gauge);
    event GaugeRevived(address indexed gauge);
    event Voted(address indexed voter, uint256 tokenId, uint256 weight);
    event Abstained(uint256 tokenId, uint256 weight);
    event Deposit(address indexed lp, address indexed gauge, uint256 tokenId, uint256 amount);
    event Withdraw(address indexed lp, address indexed gauge, uint256 tokenId, uint256 amount);
    event NotifyReward(address indexed sender, address indexed reward, uint256 amount);
    event DistributeReward(address indexed sender, address indexed gauge, uint256 amount);
    event Attach(address indexed owner, address indexed gauge, uint256 tokenId);
    event Detach(address indexed owner, address indexed gauge, uint256 tokenId);
    event Whitelisted(address indexed whitelister, address indexed token);

    constructor(
        address _ve,
        address _gauges,
        address _bribes,
        address _mana
    ) {
        veALCX = _ve;
        MANA = _mana;
        base = IVotingEscrow(_ve).token();
        gaugefactory = _gauges;
        bribefactory = _bribes;
        minter = msg.sender;
        executor = msg.sender;
        emergencyCouncil = msg.sender;
    }

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

    function initialize(address[] memory _tokens, address _minter) external {
        require(msg.sender == minter);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _whitelist(_tokens[i]);
        }
        minter = _minter;
    }

    function setExecutor(address _executor) public {
        require(msg.sender == executor);
        executor = _executor;
    }

    function setEmergencyCouncil(address _council) public {
        require(msg.sender == emergencyCouncil);
        emergencyCouncil = _council;
    }

    function reset(uint256 _tokenId) external onlyNewEpoch(_tokenId) {
        require(IVotingEscrow(veALCX).isApprovedOrOwner(msg.sender, _tokenId), "not approved or owner");

        lastVoted[_tokenId] = block.timestamp;
        _reset(_tokenId);
        IVotingEscrow(veALCX).abstain(_tokenId);
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
                IBaseGauge(gauges[_pool]).setVoteStatus(IVotingEscrow(veALCX).ownerOf(_tokenId), false);
                emit Abstained(_tokenId, _votes);
            }
        }
        totalWeight -= uint256(_totalWeight);
        usedWeights[_tokenId] = 0;
        delete poolVote[_tokenId];
    }

    function poke(uint256 _tokenId, bool _boost) external {
        address[] memory _poolVote = poolVote[_tokenId];
        uint256 _poolCnt = _poolVote.length;
        uint256[] memory _weights = new uint256[](_poolCnt);

        for (uint256 i = 0; i < _poolCnt; i++) {
            _weights[i] = votes[_tokenId][_poolVote[i]];
        }

        _vote(_tokenId, _poolVote, _weights, _boost);
    }

    function _vote(
        uint256 _tokenId,
        address[] memory _poolVote,
        uint256[] memory _weights,
        bool _boost
    ) internal {
        _reset(_tokenId);
        uint256 _poolCnt = _poolVote.length;
        // If vote is being boosted use veALCX + MANA weight
        uint256 _weight = _boost
            ? IVotingEscrow(veALCX).balanceOfNFT(_tokenId) + IVotingEscrow(veALCX).balanceOfMana(_tokenId)
            : IVotingEscrow(veALCX).balanceOfNFT(_tokenId);
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
                uint256 _poolWeight = (_weights[i] * _weight) / _totalVoteWeight;
                require(votes[_tokenId][_pool] == 0);
                require(_poolWeight != 0);
                _updateFor(_gauge);

                poolVote[_tokenId].push(_pool);

                weights[_pool] += _poolWeight;
                votes[_tokenId][_pool] += _poolWeight;
                _usedWeight += _poolWeight;
                _totalWeight += _poolWeight;
                IBaseGauge(gauges[_pool]).setVoteStatus(IVotingEscrow(veALCX).ownerOf(_tokenId), true);
                emit Voted(msg.sender, _tokenId, _poolWeight);
            }
        }
        if (_usedWeight > 0) IVotingEscrow(veALCX).voting(_tokenId);
        totalWeight += uint256(_totalWeight);
        usedWeights[_tokenId] = uint256(_usedWeight);

        // If vote is not being boosted, mint unused MANA to veALCX owner
        if (!_boost) {
            IERC20Mintable(MANA).mint(
                IVotingEscrow(veALCX).ownerOf(_tokenId),
                IVotingEscrow(veALCX).balanceOfMana(_tokenId)
            );
        }
    }

    function vote(
        uint256 _tokenId,
        address[] calldata _poolVote,
        uint256[] calldata _weights,
        bool _boost
    ) external onlyNewEpoch(_tokenId) {
        require(IVotingEscrow(veALCX).isApprovedOrOwner(msg.sender, _tokenId));
        require(_poolVote.length == _weights.length);
        lastVoted[_tokenId] = block.timestamp;
        _vote(_tokenId, _poolVote, _weights, _boost);
    }

    function whitelist(address _token) public {
        require(msg.sender == executor, "not executor");
        _whitelist(_token);
    }

    function _whitelist(address _token) internal {
        require(!isWhitelisted[_token]);
        isWhitelisted[_token] = true;
        emit Whitelisted(msg.sender, _token);
    }

    function createGauge(address _pool, GaugeType _gaugeType) external returns (address) {
        require(gauges[_pool] == address(0x0), "exists");
        require(msg.sender == executor, "only executor creates gauges");

        address _bribe = IBribeFactory(bribefactory).createBribe();
        // Handling different gauge types
        address _gauge;
        if (_gaugeType == GaugeType.Staking) {
            _gauge = IGaugeFactory(gaugefactory).createStakingGauge(_pool, _bribe, veALCX);
        } else {
            // TODO update when passthrough gague logic is completed
            // _gauge = IGaugeFactory(gaugefactory).createPassthroughGauge(_pool, _bribe, veALCX);
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

    function attachTokenToGauge(uint256 tokenId, address account) external {
        require(isGauge[msg.sender]);
        require(isAlive[msg.sender]); // killed gauges cannot attach tokens to themselves
        if (tokenId > 0) IVotingEscrow(veALCX).attach(tokenId);
        emit Attach(account, msg.sender, tokenId);
    }

    function emitDeposit(
        uint256 tokenId,
        address account,
        uint256 amount
    ) external {
        require(isGauge[msg.sender]);
        require(isAlive[msg.sender]);
        emit Deposit(account, msg.sender, tokenId, amount);
    }

    function detachTokenFromGauge(uint256 tokenId, address account) external {
        require(isGauge[msg.sender]);
        if (tokenId > 0) IVotingEscrow(veALCX).detach(tokenId);
        emit Detach(account, msg.sender, tokenId);
    }

    function emitWithdraw(
        uint256 tokenId,
        address account,
        uint256 amount
    ) external {
        require(isGauge[msg.sender]);
        emit Withdraw(account, msg.sender, tokenId, amount);
    }

    function length() external view returns (uint256) {
        return pools.length;
    }

    uint256 internal index;
    mapping(address => uint256) internal supplyIndex;
    mapping(address => uint256) public claimable;

    function notifyRewardAmount(uint256 amount) external {
        _safeTransferFrom(base, msg.sender, address(this), amount); // transfer the distro in
        uint256 _ratio = (amount * 1e18) / totalWeight; // 1e18 adjustment is removed during claim
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

    function claimRewards(address[] memory _gauges, address[][] memory _tokens) external {
        for (uint256 i = 0; i < _gauges.length; i++) {
            IBaseGauge(_gauges[i]).getReward(msg.sender, _tokens[i]);
        }
    }

    function distribute(address _gauge) public lock {
        IMinter(minter).updatePeriod();
        _updateFor(_gauge);
        uint256 _claimable = claimable[_gauge];
        if (_claimable > IBaseGauge(_gauge).left(base) && _claimable / DURATION > 0) {
            claimable[_gauge] = 0;
            IBaseGauge(_gauge).notifyRewardAmount(base, _claimable);
            emit DistributeReward(msg.sender, _gauge, _claimable);
            // distribute bribes & fees too
            IBaseGauge(_gauge).deliverBribes();
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

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}
