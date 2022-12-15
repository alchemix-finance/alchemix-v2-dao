// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

interface IBaseGauge {
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
    function deliverBribes() external;

    /**
     * @notice Add a bribe token to a gauge
     * @param token The address of the bribe token
     */
    function addBribeRewardToken(address token) external;

    /**
     * @notice Get the rewards form a gauge
     * @param account   The account claiming the rewards
     * @param tokens    The reward tokens being claimed
     */
    function getReward(address account, address[] memory tokens) external;

    /**
     * @notice Calculate the time remaining of a rewards period
     * @param token     The rewards token
     * @return uint256  Remaining duration of a rewards period
     */
    function left(address token) external view returns (uint256);

    /**
     * @notice Set the vote status of an account
     * @param account  The account being updated
     * @param voted    Whether or not the account has voted
     */
    function setVoteStatus(address account, bool voted) external;
}
