// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "./interfaces/IBribe.sol";
import "./interfaces/IBaseGauge.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title  Bribe
 * @notice Implementation of bribe contract to be used with gauges
 */
contract Bribe is IBribe {
    uint256 internal constant DURATION = 5 days; // Rewards released over voting period
    uint256 internal constant BRIBE_LAG = 1 days;
    uint256 internal constant COOLDOWN = 12 hours;
    uint256 internal constant MAX_REWARD_TOKENS = 16;

    address public gauge; // Address of the gauge that the bribes are for
    address[] public rewards;

    mapping(address => bool) public isReward;
    mapping(address => mapping(uint256 => uint256)) public tokenRewardsPerEpoch;

    // Re-entrancy check
    uint256 internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    /*
        View functions
    */

    /// @inheritdoc IBribe
    function getEpochStart(uint256 timestamp) public pure returns (uint256) {
        uint256 bribeStart = timestamp - (timestamp % (7 days)) + BRIBE_LAG;
        uint256 bribeEnd = bribeStart + DURATION - COOLDOWN;
        return timestamp < bribeEnd ? bribeStart : bribeStart + 7 days;
    }

    /// @inheritdoc IBribe
    function rewardsListLength() external view returns (uint256) {
        return rewards.length;
    }

    /*
        External functions
    */

    /// @inheritdoc IBribe
    function setGauge(address _gauge) external {
        require(gauge == address(0), "gauge already set");
        gauge = _gauge;
    }

    /// @inheritdoc IBribe
    function notifyRewardAmount(address token, uint256 amount) external lock {
        require(amount > 0);
        if (!isReward[token]) {
            require(rewards.length < MAX_REWARD_TOKENS, "too many rewards tokens");
        }
        // bribes kick in at the start of next bribe period
        uint256 adjustedTstamp = getEpochStart(block.timestamp);
        uint256 epochRewards = tokenRewardsPerEpoch[token][adjustedTstamp];

        _safeTransferFrom(token, msg.sender, address(this), amount);
        tokenRewardsPerEpoch[token][adjustedTstamp] = epochRewards + amount;

        if (!isReward[token]) {
            isReward[token] = true;
            rewards.push(token);
            IBaseGauge(gauge).addBribeRewardToken(token);
        }

        emit NotifyReward(msg.sender, token, adjustedTstamp, amount);
    }

    /// @inheritdoc IBribe
    function addRewardToken(address token) external {
        require(msg.sender == gauge);
        if (!isReward[token]) {
            require(rewards.length < MAX_REWARD_TOKENS, "too many rewards tokens");
            isReward[token] = true;
            rewards.push(token);
        }
    }

    /// @inheritdoc IBribe
    function swapOutRewardToken(
        uint256 i,
        address oldToken,
        address newToken
    ) external {
        require(msg.sender == gauge);
        require(rewards[i] == oldToken);
        isReward[oldToken] = false;
        isReward[newToken] = true;
        rewards[i] = newToken;
    }

    /// @inheritdoc IBribe
    function deliverReward(address token, uint256 epochStart) external lock returns (uint256) {
        require(msg.sender == gauge);
        uint256 rewardPerEpoch = tokenRewardsPerEpoch[token][epochStart];
        if (rewardPerEpoch > 0) {
            _safeTransfer(token, address(gauge), rewardPerEpoch);
        }
        return rewardPerEpoch;
    }

    /*
        Internal functions
    */

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
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
