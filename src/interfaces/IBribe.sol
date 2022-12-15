// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

interface IBribe {
    /**
     * @notice Emitted when the bribe amount is calculated for a given token
     * @param from     The address who called the function
     * @param reward   The address of the reward token
     * @param epoch    The epoch which the bribe occured
     * @param amount   The amount of the bribe
     */
    event NotifyReward(address indexed from, address indexed reward, uint256 epoch, uint256 amount);

    /**
     * @notice Set the gauge a bribe belongs to
     * @param _gauge The address of the gauge
     */
    function setGauge(address _gauge) external;

    /**
     * @notice Calculate the epoch start time
     * @param timestamp Provided timstamp
     * @return uint256  Timestamp of start time
     */
    function getEpochStart(uint256 timestamp) external view returns (uint256);

    /**
     * @return uint256 Length of the rewards address array
     */
    function rewardsListLength() external view returns (uint256);

    /**
     * @notice Distribute the appropriate bribes to a gauge
     * @param token     The address of the bribe token
     * @param amount    The amount of bribes being sent
     */
    function notifyRewardAmount(address token, uint256 amount) external;

    /**
     * @notice Distribute the bribes for an epoch
     * @param token         The bribe token being given
     * @param epochStart    The epoch for the bribes
     * @return uint256      Amount of bribes for the epoch
     */
    function deliverReward(address token, uint256 epochStart) external returns (uint256);

    /**
     * @return address Address of a reward token given the index
     */
    function rewards(uint256 i) external view returns (address);

    /**
     * @notice Add a token to the rewards array
     * @param token The address of the token
     */
    function addRewardToken(address token) external;

    /**
     * @notice Update a token in the rewards array
     * @param i        Index of the existing token
     * @param oldToken Token being replaced
     * @param newToken Token being added
     */
    function swapOutRewardToken(
        uint256 i,
        address oldToken,
        address newToken
    ) external;
}
