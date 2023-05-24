// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

interface IBribe {
    /// @notice Checkpoint for marking balance
    struct Checkpoint {
        uint256 timestamp;
        uint256 balanceOf;
    }

    /// @notice Checkpoint for marking supply
    struct SupplyCheckpoint {
        uint256 timestamp;
        uint256 supply;
    }

    /**
     * @notice Emitted when the bribe amount is calculated for a given token
     * @param from     The address who called the function
     * @param reward   The address of the reward token
     * @param epoch    The epoch which the bribe occured
     * @param amount   The amount of the bribe
     */
    event NotifyReward(address indexed from, address indexed reward, uint256 epoch, uint256 amount);

    /**
     * @notice Emitted when a new gauge is set.
     * @param gauge     The address of the new gauge.
     */
    event GaugeUpdated(address gauge);

    /**
     * @notice Emitted when a new reward token is added.
     * @param token     The address of the new reward token.
     */
    event RewardTokenAdded(address token);

    /**
     * @notice Emitted when a reward token is swapped for another token.
     * @param oldToken      The address of the old reward token.
     * @param newToken      The address of the new reward token.
     */
    event RewardTokenSwapped(address oldToken, address newToken);

    event Deposit(address indexed from, uint256 tokenId, uint256 amount);
    event Withdraw(address indexed from, uint256 tokenId, uint256 amount);
    event ClaimRewards(address indexed from, address indexed reward, uint256 amount);

    /**
     * @notice Set the gauge a bribe belongs to
     * @param _gauge The address of the gauge
     */
    function setGauge(address _gauge) external;

    function periodFinish(address token) external view returns (uint256);

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
     * @notice return the last time the reward was modified or periodFinish if the reward has ended
     * @param token Address of the reward token to check
     */
    function lastTimeRewardApplicable(address token) external view returns (uint256);

    /**
     * @return address Address of a reward token given the index
     */
    function rewards(uint256 i) external view returns (address);

    /**
     * @notice Determine the prior balance for an account as of a timestamp
     * @param tokenId   Id of the token check
     * @param timestamp The timestamp to get the balance at
     * @return uint256  The balance the account had as of the given timestamp
     */
    function getPriorBalanceIndex(uint256 tokenId, uint256 timestamp) external view returns (uint256);

    /**
     * @notice Allows a user to claim rewards for a given token
     * @param tokenId Id of the token who's rewards are being claimed
     * @param tokens  List of tokens being claimed
     */
    function getReward(uint256 tokenId, address[] memory tokens) external;

    /**
     * @notice Used by Voter to allow batched reward claims
     * @param tokenId Id of the token who's rewards are being claimed
     * @param tokens  List of tokens being claimed
     */
    function getRewardForOwner(uint tokenId, address[] memory tokens) external;

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
    function swapOutRewardToken(uint256 i, address oldToken, address newToken) external;

    function getPriorSupplyIndex(uint256 timestamp) external view returns (uint256);

    function earned(address token, uint256 tokenId) external view returns (uint256);

    function deposit(uint256 amount, uint256 tokenId) external;

    function withdraw(uint256 amount, uint256 tokenId) external;
}
