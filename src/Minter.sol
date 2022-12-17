// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "./libraries/Math.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IRewardsDistributor.sol";
import "./interfaces/IVoter.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IAlchemixToken.sol";

/**
 * @dev Data to initialize the minter based on current emissions
 */
struct InitializationParams {
    address voter; // The voting & distribution system
    address ve; // veALCX token system
    address rewardsDistributor; // veALCX distribution system
    uint256 supply; // Current emissions supply
    uint256 rewards; // Current amount of emissions
    uint256 stepdown; // Rate rewards decreases by
}

/**
 * @title Minter
 * @notice Contract to handle ALCX emissions and their distriubtion
 */
contract Minter is IMinter {
    // Allows minting once per epoch (epoch = 1 week, reset every Thursday 00:00 UTC)
    uint256 public constant WEEK = 86400 * 7;
    uint256 public constant TAIL_EMISSIONS_RATE = 2194e18; // Tail emissions rate
    uint256 public constant BPS = 10000;

    uint256 public epochEmissions;
    uint256 public activePeriod;
    uint256 public stepdown;
    uint256 public rewards;
    uint256 public supply;
    uint256 public veAlcxEmissionsRate; // bps of emissions going to veALCX holders

    address public admin;
    address public pendingAdmin;

    address internal initializer;

    IAlchemixToken public alcx = IAlchemixToken(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
    IVoter public immutable voter;
    IVotingEscrow public immutable ve;
    IRewardsDistributor public immutable rewardsDistributor;

    constructor(InitializationParams memory params) {
        stepdown = params.stepdown;
        rewards = params.rewards;
        supply = params.supply;
        initializer = msg.sender;
        admin = msg.sender;
        voter = IVoter(params.voter);
        ve = IVotingEscrow(params.ve);
        rewardsDistributor = IRewardsDistributor(params.rewardsDistributor);
        activePeriod = ((block.timestamp + WEEK) / WEEK) * WEEK;
        veAlcxEmissionsRate = 5000; // 50%
    }

    /*
        View functions
    */

    /// @inheritdoc IMinter
    function epochEmission() public view returns (uint256) {
        return rewards - stepdown;
    }

    /// @inheritdoc IMinter
    function circulatingEmissionsSupply() public view returns (uint256) {
        return supply;
    }

    /// @inheritdoc IMinter
    function calculateGrowth(uint256 _minted) public view returns (uint256) {
        return (_minted * veAlcxEmissionsRate) / BPS;
    }

    function initialize() external {
        require(initializer == msg.sender);
        initializer = address(0);
    }

    /*
        External functions
    */

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "not admin");
        pendingAdmin = _admin;
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "not pending admin");
        admin = pendingAdmin;
    }

    /// @inheritdoc IMinter
    function setVeAlcxEmissionsRate(uint256 _veAlcxEmissionsRate) external {
        require(msg.sender == admin, "not admin");
        veAlcxEmissionsRate = _veAlcxEmissionsRate;
    }

    /// @inheritdoc IMinter
    function updatePeriod() external returns (uint256) {
        uint256 period = activePeriod;

        if (block.timestamp >= period + WEEK && initializer == address(0)) {
            // Only trigger if new epoch
            period = (block.timestamp / WEEK) * WEEK;
            activePeriod = period;
            epochEmissions = epochEmission();

            uint256 veAlcxEmissions = calculateGrowth(epochEmissions);
            uint256 balanceOf = alcx.balanceOf(address(this));

            if (balanceOf < epochEmissions) alcx.mint(address(this), epochEmissions - balanceOf);

            // Set rewards for next epoch
            rewards -= stepdown;

            // Adjust updated emissions total
            supply += rewards;

            // Once we reach the emissions tail stepdown is 0
            if (rewards <= TAIL_EMISSIONS_RATE) {
                stepdown = 0;
            }

            // Logic to distrubte minted tokens
            alcx.approve(address(rewardsDistributor), veAlcxEmissions);
            require(alcx.transfer(address(rewardsDistributor), veAlcxEmissions));
            rewardsDistributor.checkpointToken(); // Checkpoint token balance that was just minted in rewards distributor
            rewardsDistributor.checkpointTotalSupply(); // Checkpoint supply

            alcx.approve(address(voter), epochEmissions - veAlcxEmissions);
            voter.notifyRewardAmount(epochEmissions - veAlcxEmissions);

            emit Mint(msg.sender, epochEmissions, circulatingEmissionsSupply());
        }
        return period;
    }
}
