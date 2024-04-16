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
        address timeGauge; // TIME gauge
        address treasury; // Treasury address
        uint256 supply; // Current emissions supply
        uint256 rewards; // Current amount of emissions
        uint256 stepdown; // Rate rewards decreases by
    }

    /**
     * @notice  Emitted when admin is updated
     * @param newAdmin             New admin of the contract
     */
    event AdminUpdated(address newAdmin);

    /**
     * @notice Emitted when emissions are minted
     * @param sender               Address that triggered the mint for a given period
     * @param epochEmissions       Amount of emissions minted
     * @param circulatingEmissions Supply of circulating emissions
     */
    event Mint(address indexed sender, uint256 epochEmissions, uint256 circulatingEmissions);

    /**
     * @notice  Emitted when emissions rate is updated
     * @param veAlcxEmissionsRate The new emissions rate.
     */
    event SetVeAlcxEmissionsRate(uint256 veAlcxEmissionsRate);

    /**
     * @notice  Emitted when treasury address is updated
     * @param treasury The new treasury address
     */
    event TreasuryUpdated(address treasury);

    /**
     * @notice Set the treasury address
     * @param _treasury Address of the treasury
     */
    function setTreasury(address _treasury) external;

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
     * @notice Calculate the amount of emissions to be distributed
     * @param _emissions  Amount of emissions to be minted for an epoch
     * @param _rate    Rate of emissions to be distributed
     * @return uint256 Amount of emissions distributed to veALCX stakers
     */
    function calculateEmissions(uint256 _emissions, uint256 _rate) external view returns (uint256);

    /**
     * @notice Updates the epoch, mints new emissions, sends emissions to rewards distributor and voter
     * @return uint256 The current period
     * @dev Can only be called once per epoch
     */
    function updatePeriod() external returns (uint256);

    function activePeriod() external view returns (uint256);

    function DURATION() external view returns (uint256);
}
