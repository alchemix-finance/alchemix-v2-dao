// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "src/interfaces/IMinter.sol";
import "src/interfaces/IRewardsDistributor.sol";
import "src/interfaces/IVoter.sol";
import "src/interfaces/IVotingEscrow.sol";
import "src/interfaces/IAlchemixToken.sol";
import "src/interfaces/IRevenueHandler.sol";
import "src/interfaces/synthetix/IStakingRewards.sol";
import "src/libraries/Math.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

/**
 * @title Minter
 * @notice Contract to handle ALCX emissions and their distriubtion
 */
contract Minter is IMinter {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Allows minting once per epoch (epoch = 2 week, reset every Thursday 00:00 UTC)
    uint256 public immutable DURATION = 2 weeks;
    uint256 public immutable BPS = 10_000;
    uint256 public constant TAIL_EMISSIONS_RATE = 2194e18; // Tail emissions rate

    uint256 public epochEmissions;
    uint256 public activePeriod;
    uint256 public stepdown;
    uint256 public rewards;
    uint256 public supply;
    uint256 public veAlcxEmissionsRate; // bps of emissions going to veALCX holders
    uint256 public timeEmissionsRate; // bps of emissions going to TIME stakers
    uint256 public treasuryEmissionsRate; // bps of emissions going to treasury

    address public admin;
    address public pendingAdmin;
    address public initializer;
    address public treasury;

    IAlchemixToken public immutable alcx;
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
        treasury = params.treasury;
        activePeriod = ((block.timestamp + DURATION) / DURATION) * DURATION;
        veAlcxEmissionsRate = 2500; // 25%
        timeEmissionsRate = 2000; // 20%
        treasuryEmissionsRate = 1500; // 15%
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
    function calculateEmissions(uint256 _emissions, uint256 _rate) public pure returns (uint256) {
        return _emissions.mul(_rate).div(BPS);
    }

    function initialize() external {
        require(initializer == msg.sender, "not initializer");
        require(msg.sender != address(0), "already initialized");
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
        emit AdminUpdated(pendingAdmin);
    }

    function setTreasury(address _treasury) external {
        require(msg.sender == admin, "not admin");
        require(_treasury != address(0), "treasury cannot be 0x0");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    /// @inheritdoc IMinter
    function setVeAlcxEmissionsRate(uint256 _veAlcxEmissionsRate) external {
        require(msg.sender == admin, "not admin");
        require(_veAlcxEmissionsRate <= BPS, "cannot be greater than 100%");
        veAlcxEmissionsRate = _veAlcxEmissionsRate;
        emit SetVeAlcxEmissionsRate(_veAlcxEmissionsRate);
    }

    /// @inheritdoc IMinter
    function updatePeriod() external returns (uint256) {
        require(msg.sender == address(voter), "not voter");

        uint256 period = activePeriod;

        if (block.timestamp >= period + DURATION && initializer == address(0)) {
            // Only trigger if new epoch
            period = (block.timestamp / DURATION) * DURATION;
            activePeriod = period;
            epochEmissions = epochEmission();

            uint256 veAlcxEmissions = calculateEmissions(epochEmissions, veAlcxEmissionsRate);
            uint256 timeEmissions = calculateEmissions(epochEmissions, timeEmissionsRate);
            uint256 treasuryEmissions = calculateEmissions(epochEmissions, treasuryEmissionsRate);
            uint256 gaugeEmissions = epochEmissions.sub(veAlcxEmissions).sub(timeEmissions).sub(treasuryEmissions);
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

            // If there are no votes, send emissions to veALCX holders
            if (voter.totalWeight() > 0) {
                alcx.approve(address(voter), gaugeEmissions);
                voter.notifyRewardAmount(gaugeEmissions);
            } else {
                veAlcxEmissions += gaugeEmissions;
            }

            // Logic to distrubte minted tokens
            IERC20(address(alcx)).safeTransfer(address(rewardsDistributor), veAlcxEmissions);
            rewardsDistributor.checkpointToken(); // Checkpoint token balance that was just minted in rewards distributor
            rewardsDistributor.checkpointTotalSupply(); // Checkpoint supply

            IERC20(address(alcx)).safeTransfer(address(timeGauge), timeEmissions);
            timeGauge.notifyRewardAmount(timeEmissions);

            IERC20(address(alcx)).safeTransfer(treasury, treasuryEmissions);

            revenueHandler.checkpoint();

            emit Mint(msg.sender, epochEmissions, supply);
        }
        return period;
    }
}
