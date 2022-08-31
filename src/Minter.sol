// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "./libraries/Math.sol";
import "./interfaces/IRewardsDistributor.sol";
import "./interfaces/IVelo.sol";
import "./interfaces/IVoter.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IAlchemixToken.sol";

struct InitializationParams {
    address voter; // the voting & distribution system
    address ve; // the ve(3,3) system that will be locked into
    address rewardsDistributor; // the distribution system that ensures users aren't diluted
    uint256 supply; // current emissions supply
    uint256 rewards; // current amount of emissions
    uint256 stepdown; // rate rewards decreases by
}

contract Minter {
    // Allows minting once per epoch (epoch = 1 week, reset every Thursday 00:00 UTC)
    uint256 internal constant WEEK = 86400 * 7;

    // Tail emissions rate
    uint256 public constant TAIL_EMISSIONS_RATE = 2194e18;

    IAlchemixToken public alcx = IAlchemixToken(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
    IVoter public immutable voter;
    IVotingEscrow public immutable ve;
    IRewardsDistributor public immutable rewardsDistributor;

    uint256 public epochEmissions;

    uint256 public activePeriod;

    address internal initializer;
    address public admin;
    address public pendingAdmin;

    uint256 public stepdown;
    uint256 public rewards;
    uint256 public supply;

    event Mint(address indexed sender, uint256 epoch, uint256 circulatingSupply, uint256 circulatingEmissions);

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
    }

    // Remove if contract is not upgradeable
    function initialize() external {
        require(initializer == msg.sender);
        initializer = address(0);
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "not admin");
        pendingAdmin = _admin;
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "not pending admin");
        admin = pendingAdmin;
    }

    // Circulating supply is total token supply - locked supply
    function circulatingAlcxSupply() public view returns (uint256) {
        return alcx.totalSupply() - ve.totalSupply();
    }

    // Amount of emission for the current epoch
    function epochEmission() public view returns (uint256) {
        return rewards - stepdown;
    }

    function circulatingEmissionsSupply() public view returns (uint256) {
        return supply;
    }

    // TODO logic to distrubte minted tokens to veALCX holders
    // calculate inflation and adjust ve balances accordingly
    // function veGrowth(uint256 _minted) public view returns (uint256) {
    // 	uint256 _veTotal = ve.totalSupply();
    // 	uint256 _alcxTotal = alcx.totalSupply();
    // 	return (((((_minted * _veTotal) / _alcxTotal) * _veTotal) / _alcxTotal) * _veTotal) / _alcxTotal / 2;
    // }

    // update period can only be called once per epoch (1 week)
    function updatePeriod() external returns (uint256) {
        uint256 _period = activePeriod;

        if (block.timestamp >= _period + WEEK && initializer == address(0)) {
            // only trigger if new epoch
            _period = (block.timestamp / WEEK) * WEEK;
            activePeriod = _period;
            epochEmissions = epochEmission();

            alcx.mint(address(this), epochEmissions);

            // Set rewards for next epoch
            rewards -= stepdown;

            // Adjust updated emissions total
            supply += rewards;

            // Once we reach the emissions tail stepdown is 0
            if (rewards <= TAIL_EMISSIONS_RATE) {
                stepdown = 0;
            }

            // TODO logic to distrubte minted tokens to veALCX holders
            // require(alcx.transfer(address(rewardsDistributor), _growth));
            // rewardsDistributor.checkpointToken(); // checkpoint token balance that was just minted in rewards distributor
            // rewardsDistributor.checkpointTotalSupply(); // checkpoint supply

            // alcx.approve(address(voter), epoch);
            // voter.notifyRewardAmount(epoch);

            emit Mint(msg.sender, epochEmissions, circulatingAlcxSupply(), circulatingEmissionsSupply());
        }
        return _period;
    }
}
