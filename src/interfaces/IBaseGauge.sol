// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

interface IBaseGauge {
    enum VotingStage {
        BribesPhase,
        VotesPhase,
        RewardsPhase
    }

    /// @notice A checkpoint for marking balance
    struct Checkpoint {
        uint256 timestamp;
        uint256 balanceOf;
    }

    /// @notice A checkpoint for marking reward rate
    struct RewardPerTokenCheckpoint {
        uint256 timestamp;
        uint256 rewardPerToken;
    }

    /// @notice A checkpoint for marking supply
    struct SupplyCheckpoint {
        uint256 timestamp;
        uint256 supply;
    }

    /**
     * @notice Emitted when the reward amount is calculated for a given token
     * @param from     The address who called the function
     * @param reward   The address of the reward token
     * @param amount   The amount of the reward
     */
    event NotifyReward(address indexed from, address indexed reward, uint256 amount);
    /**
     * @notice Emitted when rewards are claimed
     * @param from     The address who called the function
     * @param reward   The address of the reward token
     * @param amount   The amount of the reward
     */
    event ClaimRewards(address indexed from, address indexed reward, uint256 amount);

    /**
     * @notice Emitted when rewards are passed to a gauge
     * @param from     The address who called the function
     * @param token    The address of the reward token
     * @param amount   The amount of the reward
     * @param receiver The destination address of the rewards
     */
    event Passthrough(address indexed from, address token, uint256 amount, address receiver);

    function setAdmin(address _admin) external;

    function acceptAdmin() external;

    function rewardsListLength() external view returns (uint256);

    /**
     * @notice Distribute the appropriate rewards to a gauge
     * @param token     The address of the reward token
     * @param amount    The amount of rewards being sent
     */
    function notifyRewardAmount(address token, uint256 amount) external;

    /**
     * @notice Add a bribe token to a gauge
     * @param token The address of the bribe token
     */
    function addBribeRewardToken(address token) external;
}
