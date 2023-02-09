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

    /**
     * @notice Distribute the appropriate rewards to a gauge
     * @param token     The address of the reward token
     * @param amount    The amount of rewards being sent
     */
    function notifyRewardAmount(address token, uint256 amount) external;

    /**
     * @notice Distribute the appropriate bribes to a gauge
     */
    // function deliverBribes() external;

    /**
     * @notice Add a bribe token to a gauge
     * @param token The address of the bribe token
     */
    function addBribeRewardToken(address token) external;

    /**
     * @notice Estimation, not exact until the supply > rewardPerToken calculations have run
     * @param token   address of reward token
     * @param account account claiming rewards
     */
    function earned(address token, address account) external view returns (uint256);

    /**
     * @notice Get the rewards form a gauge
     * @param account   The account claiming the rewards
     * @param tokens    The reward tokens being claimed
     */
    function getReward(address account, address[] memory tokens) external;

    /**
     * @notice Determine the prior balance for an account as of a block number
     * @param account The address of the account to check
     * @param timestamp The timestamp to get the balance at
     * @return The balance the account had as of the given block
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     */
    function getPriorBalanceIndex(address account, uint256 timestamp) external view returns (uint256);

    /**
     * @notice Calculate the time remaining of a rewards period
     * @param token     The rewards token
     * @return uint256  Remaining duration of a rewards period
     */
    function left(address token) external view returns (uint256);

    /**
     * @dev Update stored rewardPerToken values without the last one snapshot
     * @notice If the contract will get "out of gas" error on users actions this will be helpful
     */
    function batchUpdateRewardPerToken(address token, uint256 maxRuns) external;
}
