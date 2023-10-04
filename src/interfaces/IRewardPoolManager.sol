// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

interface IRewardPoolManager {
    event TreasuryUpdated(address indexed newTreasury);
    event AdminUpdated(address admin);
    event RewardPoolUpdated(address newRewardPool);
    event PoolTokenUpdated(address newPoolToken);
    event VeALCXUpdated(address newVeALCX);
    event ClaimRewardPoolRewards(address indexed claimer, address rewardToken, uint256 rewardAmount);

    /**
     * @notice Set the address responsible for administration
     * @param _admin Address that enables the administration of FLUX
     * @dev This function reverts if the caller does not have the admin role.
     */
    function setAdmin(address _admin) external;

    /**
     * @notice Accept the address responsible for administration
     * @dev This function reverts if the caller does not have the pendingAdmin role.
     */
    function acceptAdmin() external;

    /**
     * @notice Set the treasury address
     * @param _treasury Treasury address
     * @dev This function reverts if the caller does not have the admin role.
     */
    function setTreasury(address _treasury) external;

    /**
     * @notice Set the rewardPool address
     * @param _newRewardPool RewardPool address
     * @dev This function reverts if the caller does not have the admin role.
     */
    function setRewardPool(address _newRewardPool) external;

    /**
     * @notice Set the poolToken address
     * @param _newPoolToken PoolToken address
     * @dev This function reverts if the caller does not have the admin role.
     */
    function setPoolToken(address _newPoolToken) external;

    /**
     * @notice Set the veALCX address
     * @param _newVeALCX veALCX address
     * @dev This function reverts if the caller does not have the admin role.
     */
    function setVeALCX(address _newVeALCX) external;

    /**
     * @notice Deposit amount into rewardPool
     * @param _amount Amount to deposit
     */
    function depositIntoRewardPool(uint256 _amount) external returns (bool);

    /**
     * @notice Withdraw amount from rewardPool
     * @param _amount Amount to withdraw
     */
    function withdrawFromRewardPool(uint256 _amount) external returns (bool);

    /**
     * @notice Claim rewards from the rewardPool
     */
    function claimRewardPoolRewards() external;

    /**
     * @notice Add a rewardPoolToken
     * @param _token Address of the token to add
     */
    function addRewardPoolToken(address _token) external;

    /**
     * @notice Add multiple rewardPoolTokens
     * @param _tokens Addresses of the tokens to add
     */
    function addRewardPoolTokens(address[] calldata _tokens) external;

    /**
     * @notice Swap a rewardPoolToken
     * @param i Index of the token to swap
     * @param oldToken Address of the token to remove
     * @param newToken Address of the token to add
     */
    function swapOutRewardPoolToken(uint256 i, address oldToken, address newToken) external;
}
