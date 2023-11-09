// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "src/interfaces/IBribe.sol";
import "src/interfaces/IBaseGauge.sol";
import "src/interfaces/IVoter.sol";
import "src/interfaces/IVotingEscrow.sol";
import "src/libraries/Math.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title  Bribe
 * @notice Implementation of bribe contract to be used with gauges
 */
contract Bribe is IBribe {
    uint256 internal constant DURATION = 2 weeks; // Rewards released over voting period
    uint256 internal constant BRIBE_LAG = 1 days;
    uint256 internal constant MAX_REWARD_TOKENS = 16;

    /// @notice The number of checkpoints
    uint256 public supplyNumCheckpoints;
    uint256 public votingNumCheckpoints;
    uint256 public totalSupply;
    uint256 public totalVoting;

    address public immutable veALCX;
    address public immutable voter;
    address public gauge; // Address of the gauge that the bribes are for
    address[] public rewards;

    /// @notice A record of balance checkpoints for each account, by index
    mapping(uint256 => mapping(uint256 => Checkpoint)) public checkpoints;
    /// @notice The number of checkpoints for each account
    mapping(uint256 => uint256) public numCheckpoints;
    /// @notice A record of balance checkpoints for each token, by index
    mapping(uint256 => SupplyCheckpoint) public supplyCheckpoints;
    mapping(uint256 => VotingCheckpoint) public votingCheckpoints;
    mapping(address => bool) public isReward;
    mapping(address => mapping(uint256 => uint256)) public tokenRewardsPerEpoch;
    mapping(uint256 => uint256) public balanceOf;
    mapping(address => uint256) public periodFinish;
    mapping(address => mapping(uint256 => uint256)) public lastEarn;

    // Re-entrancy check
    uint256 internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    constructor(address _voter) {
        voter = _voter;
        veALCX = IVoter(_voter).veALCX();
    }

    /*
        View functions
    */

    /// @inheritdoc IBribe
    function getEpochStart(uint256 timestamp) public pure returns (uint256) {
        uint256 bribeStart = _bribeStart(timestamp);
        uint256 bribeEnd = bribeStart + DURATION;

        return timestamp < bribeEnd ? bribeStart : bribeStart + DURATION;
    }

    /// @inheritdoc IBribe
    function rewardsListLength() external view returns (uint256) {
        return rewards.length;
    }

    /// @inheritdoc IBribe
    function lastTimeRewardApplicable(address token) public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish[token]);
    }

    /*
        External functions
    */

    /// @inheritdoc IBribe
    function setGauge(address _gauge) external {
        require(gauge == address(0), "gauge already set");
        gauge = _gauge;
        emit GaugeUpdated(_gauge);
    }

    /// @inheritdoc IBribe
    function notifyRewardAmount(address token, uint256 amount) external lock {
        require(amount > 0);

        // If the token has been whitelisted by the voter contract, add it to the rewards list
        require(IVoter(voter).isWhitelisted(token), "bribe tokens must be whitelisted");
        _addRewardToken(token);

        // bribes kick in at the start of next bribe period
        uint256 adjustedTstamp = getEpochStart(block.timestamp);
        uint256 epochRewards = tokenRewardsPerEpoch[token][adjustedTstamp];

        _safeTransferFrom(token, msg.sender, address(this), amount);
        tokenRewardsPerEpoch[token][adjustedTstamp] = epochRewards + amount;
        periodFinish[token] = adjustedTstamp + DURATION;

        emit NotifyReward(msg.sender, token, adjustedTstamp, amount);
    }

    /// @inheritdoc IBribe
    function addRewardToken(address token) external {
        require(msg.sender == gauge);
        _addRewardToken(token);
    }

    /// @inheritdoc IBribe
    function swapOutRewardToken(uint256 i, address oldToken, address newToken) external {
        require(msg.sender == voter);
        require(IVoter(voter).isWhitelisted(newToken), "bribe tokens must be whitelisted");
        require(rewards[i] == oldToken);
        require(newToken != address(0));

        isReward[oldToken] = false;
        isReward[newToken] = true;
        rewards[i] = newToken;

        emit RewardTokenSwapped(oldToken, newToken);
    }

    /// @inheritdoc IBribe
    function getPriorBalanceIndex(uint256 tokenId, uint256 timestamp) public view returns (uint256) {
        uint256 nCheckpoints = numCheckpoints[tokenId];
        if (nCheckpoints == 0) {
            return 0;
        }
        // First check most recent balance
        if (checkpoints[tokenId][nCheckpoints - 1].timestamp <= timestamp) {
            return (nCheckpoints - 1);
        }
        // Next check implicit zero balance
        if (checkpoints[tokenId][0].timestamp > timestamp) {
            return 0;
        }

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[tokenId][center];
            if (cp.timestamp == timestamp) {
                return center;
            } else if (cp.timestamp < timestamp) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return lower;
    }

    function getPriorVotingIndex(uint256 timestamp) public view returns (uint256) {
        uint256 nCheckpoints = votingNumCheckpoints;
        if (nCheckpoints == 0) {
            return 0;
        }

        // Check most recent balance
        if (votingCheckpoints[nCheckpoints - 1].timestamp <= timestamp) {
            return (nCheckpoints - 1);
        }

        // Check implicit zero balance
        if (votingCheckpoints[0].timestamp > timestamp) {
            return 0;
        }

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            VotingCheckpoint memory cp = votingCheckpoints[center];
            if (cp.timestamp == timestamp) {
                return center;
            } else if (cp.timestamp < timestamp) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return lower;
    }

    function earned(address token, uint256 tokenId) public view returns (uint256) {
        if (numCheckpoints[tokenId] == 0) {
            return 0;
        }

        uint256 _startTimestamp = lastEarn[token][tokenId];

        // Prevent earning twice within an epoch
        if (block.timestamp - _startTimestamp < DURATION) {
            return 0;
        }

        uint256 _startIndex = getPriorBalanceIndex(tokenId, _startTimestamp);
        uint256 _endIndex = numCheckpoints[tokenId] - 1;

        uint256 reward = 0;
        // you only earn once per epoch (after it's over)
        Checkpoint memory prevRewards; // reuse struct to avoid stack too deep
        prevRewards.timestamp = _bribeStart(_startTimestamp);
        uint256 _prevSupply = 1;

        if (_endIndex >= 0) {
            for (uint256 i = _startIndex; i <= _endIndex; i++) {
                Checkpoint memory cp0 = checkpoints[tokenId][i];
                uint256 _nextEpochStart = _bribeStart(cp0.timestamp);
                // check that you've earned it
                // this won't happen until a week has passed
                if (_nextEpochStart > prevRewards.timestamp) {
                    reward += prevRewards.balanceOf;
                }

                if (_startIndex == _endIndex) break;

                prevRewards.timestamp = _nextEpochStart;
                _prevSupply = votingCheckpoints[getPriorVotingIndex(_nextEpochStart + DURATION)].votes;

                // Prevent divide by zero
                if (_prevSupply == 0) {
                    _prevSupply = 1;
                }
                prevRewards.balanceOf = (cp0.balanceOf * tokenRewardsPerEpoch[token][_nextEpochStart]) / _prevSupply;
            }
        }

        Checkpoint memory cp = checkpoints[tokenId][_endIndex];
        uint256 _lastEpochStart = _bribeStart(cp.timestamp);
        uint256 _lastEpochEnd = _lastEpochStart + DURATION;
        uint256 _priorSupply = votingCheckpoints[getPriorVotingIndex(_lastEpochEnd)].votes;

        // Prevent divide by zero
        if (_priorSupply == 0) {
            _priorSupply = 1;
        }

        if (block.timestamp > _lastEpochEnd) {
            reward += (cp.balanceOf * tokenRewardsPerEpoch[token][_lastEpochStart]) / _priorSupply;
        }

        return reward;
    }

    /// @inheritdoc IBribe
    function getRewardForOwner(uint256 tokenId, address[] memory tokens) external lock {
        require(msg.sender == voter, "not voter");
        address _owner = IVotingEscrow(veALCX).ownerOf(tokenId);
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 _reward = earned(tokens[i], tokenId);

            require(_reward > 0, "no rewards to claim");

            lastEarn[tokens[i]][tokenId] = block.timestamp;

            _writeCheckpoint(tokenId, balanceOf[tokenId]);
            _writeSupplyCheckpoint();

            _safeTransfer(tokens[i], _owner, _reward);

            emit ClaimRewards(_owner, tokens[i], _reward);
        }
    }

    function deposit(uint256 amount, uint256 tokenId) external {
        require(msg.sender == voter);

        totalSupply += amount;
        balanceOf[tokenId] += amount;

        totalVoting += amount;

        _writeCheckpoint(tokenId, balanceOf[tokenId]);
        _writeSupplyCheckpoint();
        _writeVotingCheckpoint();

        emit Deposit(msg.sender, tokenId, amount);
    }

    function withdraw(uint256 amount, uint256 tokenId) external {
        require(msg.sender == voter);

        totalSupply -= amount;
        balanceOf[tokenId] -= amount;

        _writeCheckpoint(tokenId, balanceOf[tokenId]);
        _writeSupplyCheckpoint();

        emit Withdraw(msg.sender, tokenId, amount);
    }

    /// @inheritdoc IBribe
    function resetVoting() external {
        require(msg.sender == voter);
        totalVoting = 0;
    }

    /*
        Internal functions
    */

    function _addRewardToken(address token) internal {
        if (!isReward[token] && token != address(0)) {
            require(rewards.length < MAX_REWARD_TOKENS, "too many rewards tokens");
            require(IVoter(voter).isWhitelisted(token), "bribe tokens must be whitelisted");

            isReward[token] = true;
            rewards.push(token);
        }
    }

    function _writeCheckpoint(uint256 tokenId, uint256 balance) internal {
        uint256 _timestamp = block.timestamp;
        uint256 _nCheckPoints = numCheckpoints[tokenId];
        if (_nCheckPoints > 0 && checkpoints[tokenId][_nCheckPoints - 1].timestamp == _timestamp) {
            checkpoints[tokenId][_nCheckPoints - 1].balanceOf = balance;
        } else {
            checkpoints[tokenId][_nCheckPoints] = Checkpoint(_timestamp, balance);
            numCheckpoints[tokenId] = _nCheckPoints + 1;
        }
    }

    function _writeVotingCheckpoint() internal {
        uint256 _nCheckPoints = votingNumCheckpoints;
        uint256 _timestamp = block.timestamp;

        if (_nCheckPoints > 0 && votingCheckpoints[_nCheckPoints - 1].timestamp == _timestamp) {
            votingCheckpoints[_nCheckPoints - 1].votes = totalVoting;
        } else {
            votingCheckpoints[_nCheckPoints] = VotingCheckpoint(_timestamp, totalVoting);
            votingNumCheckpoints = _nCheckPoints + 1;
        }
    }

    function _writeSupplyCheckpoint() internal {
        uint256 _nCheckPoints = supplyNumCheckpoints;
        uint256 _timestamp = block.timestamp;

        if (_nCheckPoints > 0 && supplyCheckpoints[_nCheckPoints - 1].timestamp == _timestamp) {
            supplyCheckpoints[_nCheckPoints - 1].supply = totalSupply;
        } else {
            supplyCheckpoints[_nCheckPoints] = SupplyCheckpoint(_timestamp, totalSupply);
            supplyNumCheckpoints = _nCheckPoints + 1;
        }
    }

    function _bribeStart(uint256 timestamp) internal pure returns (uint256) {
        return timestamp - (timestamp % (DURATION));
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}
