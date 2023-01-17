// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

interface IMinter {
    /**
     * @dev Data to initialize the minter based on current emissions
     */
    struct InitializationParams {
        address alcx;
        address voter; // The voting & distribution system
        address ve; // veALCX token system
        address rewardsDistributor; // veALCX distribution system
        address revenueHandler; // veALCX revenue handler
        uint256 supply; // Current emissions supply
        uint256 rewards; // Current amount of emissions
        uint256 stepdown; // Rate rewards decreases by
    }

    /**
     * @notice Emitted when emissions are minted
     * @param sender               Address that triggered the mint for a given period
     * @param epochEmissions       Amount of emissions minted
     * @param circulatingEmissions Supply of circulating emissions
     */
    event Mint(address indexed sender, uint256 epochEmissions, uint256 circulatingEmissions);

    /**
     * @notice Sets the emissions rate of rewards sent to veALCX stakers
     * @param _veAlcxEmissionsRate The rate in BPS
     */
    function setVeAlcxEmissionsRate(uint256 _veAlcxEmissionsRate) external;

    /**
     * @notice Returns the amount of emissions
     * @return uint256 Amount of emissions for current epoch
     */
    function epochEmission() external view returns (uint256);

    /**
     * @notice Returns the amount of emissions in circulation
     * @return uint256 Amount of emissions in circulation
     */
    function circulatingEmissionsSupply() external view returns (uint256);

    /**
     * @notice Governance-defined portion of emissions sent to veALCX stakers
     * @param _minted  Amount of emissions to be minted for an epoch
     * @return uint256 Amount of emissions distributed to veALCX stakers
     */
    function calculateGrowth(uint256 _minted) external view returns (uint256);

    /**
     * @notice Updates the epoch, mints new emissions, sends emissions to rewards distributor and voter
     * @return uint256 The current period
     * @dev Can only be called once per epoch
     */
    function updatePeriod() external returns (uint256);
}
