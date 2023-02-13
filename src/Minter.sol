// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "src/interfaces/IMinter.sol";
import "src/interfaces/IRewardsDistributor.sol";
import "src/interfaces/IVoter.sol";
import "src/interfaces/IVotingEscrow.sol";
import "src/interfaces/IAlchemixToken.sol";
import "src/interfaces/IRevenueHandler.sol";
import "src/libraries/Math.sol";
import "./interfaces/synthetix/IStakingRewards.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Minter
 * @notice Contract to handle ALCX emissions and their distriubtion
 */
contract Minter is IMinter {
    using SafeERC20 for IERC20;
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
    uint256 public timeEmissionsRate; // bps of emissions going to TIME stakers

    address public admin;
    address public pendingAdmin;
    address public initializer;

    bool public initialized;

    IAlchemixToken public alcx;
    IVoter public immutable voter;
    IVotingEscrow public immutable ve;
    IRewardsDistributor public immutable rewardsDistributor;
    IRevenueHandler public immutable revenueHandler;
    IStakingRewards public immutable timeGauge;

    constructor(InitializationParams memory params) {
        stepdown = params.stepdown;
        rewards = params.rewards;
        supply = params.supply;
        initializer = msg.sender;
        admin = msg.sender;
        alcx = IAlchemixToken(params.alcx);
        voter = IVoter(params.voter);
        ve = IVotingEscrow(params.ve);
        rewardsDistributor = IRewardsDistributor(params.rewardsDistributor);
        revenueHandler = IRevenueHandler(params.revenueHandler);
        timeGauge = IStakingRewards(params.timeGauge);
        activePeriod = ((block.timestamp + WEEK) / WEEK) * WEEK;
        veAlcxEmissionsRate = 5000; // 50%
        timeEmissionsRate = 2000; // 20%
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
        require(msg.sender != address(0));
        require(initialized == false, "already initialized");
        require(initializer == msg.sender, "not initializer");
        initializer = address(0);
        initialized = true;
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
            uint256 timeEmissions = (epochEmissions * timeEmissionsRate) / BPS;
            uint256 gaugeEmissions = epochEmissions - veAlcxEmissions - timeEmissions;
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
            IERC20(address(alcx)).safeTransfer(address(rewardsDistributor), veAlcxEmissions);
            rewardsDistributor.checkpointToken(); // Checkpoint token balance that was just minted in rewards distributor
            rewardsDistributor.checkpointTotalSupply(); // Checkpoint supply

            alcx.approve(address(voter), gaugeEmissions);
            voter.notifyRewardAmount(gaugeEmissions);

            alcx.approve(address(timeGauge), timeEmissions);
            IERC20(address(alcx)).safeTransfer(address(timeGauge), timeEmissions);
            timeGauge.notifyRewardAmount(timeEmissions);

            revenueHandler.checkpoint();

            emit Mint(msg.sender, epochEmissions, circulatingEmissionsSupply());
        }
        return period;
    }
}
