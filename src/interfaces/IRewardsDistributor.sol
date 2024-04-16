// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

interface IRewardsDistributor {
    /**
     * @notice Emitted when the depositor is set
     * @param depositor Time contracts depositor
     */
    event DepositorUpdated(address depositor);

    /**
     * @notice Emitted when a checkpoint is recorded
     * @param time Time of checkpoint
     * @param tokens Rewards to distribute
     */
    event CheckpointToken(uint256 time, uint256 tokens);

    /**
     * @notice Emitted when veALCX rewards are claimed
     * @param tokenId ID of token claiming rewards
     * @param amount Amount of rewards claimed
     * @param claimEpoch Epoch when rewards were claimed
     * @param maxEpoch Most recent epoch for a given veALCX
     */
    event Claimed(uint256 tokenId, uint256 amount, uint256 claimEpoch, uint256 maxEpoch);

    /**
     * @notice Checkpoint token balance minted in rewards distributor
     */
    function checkpointToken() external;

    /**
     * @notice Checkpoint supply
     */
    function checkpointTotalSupply() external;

    /**
     * @notice Amount of ALCX available to be claimed for a veALCX position
     * @param _tokenId ID of the token
     * @return Amount of ALCX claimable
     */
    function claimable(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Get the amount of ETH or WETH required to create balanced pool deposit
     * @param _alcxAmount Amount of ALCX that will make up the balanced deposit
     * @return uint256 Amount of ETH or WETH
     * @return uint256[] Normalized weights of the pool. Prevents an additional lookup of weights
     */
    function amountToCompound(uint256 _alcxAmount) external view returns (uint256, uint256[] memory);

    /**
     * @notice Claim ALCX rewards for a given veALCX position
     * @param _tokenId ID of the token
     * @param _compound Indicator that determines if rewards are being compounded
     * @return uint256 Amount of ALCX that was either claimed or compounded
     */
    function claim(uint256 _tokenId, bool _compound) external payable returns (uint256);

    /**
     * @notice Get the balancer pool ID, address, and vault address
     * @return Balancer pool ID
     * @return Balancer pool address
     * @return Balancer vault address
     */
    function getBalancerInfo() external view returns (bytes32, address, address);
}
