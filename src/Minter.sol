// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "./libraries/Math.sol";
import "./interfaces/IRewardsDistributor.sol";
import "./interfaces/IVelo.sol";
import "./interfaces/IVoter.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IAlchemicToken.sol";

import { IERC20Mintable } from "./interfaces/IERC20Mintable.sol";

struct InitializationParams {
	address voter; // the voting & distribution system
	address ve; // the ve(3,3) system that will be locked into
	address rewardsDistributor; // the distribution system that ensures users aren't diluted
	address alcx;
	uint256 supply;
	uint256 rewards;
	uint256 stepdown;
}

contract Minter {
	uint256 internal constant WEEK = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
	uint256 internal constant EMISSION = 990;
	uint256 internal constant PRECISION = 1000;
	uint256 internal constant TAIL = 2194 * 10e18;
	uint256 internal constant BLOCKS_PER_WEEK = 45000 * 10e18;

	IERC20Mintable public alcx = IERC20Mintable(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
	IVoter public immutable voter;
	IVotingEscrow public immutable ve;
	IRewardsDistributor public immutable rewardsDistributor;

	uint256 public weekly = 15000000e18;
	uint256 public activePeriod;

	address internal initializer;
	address public admin;
	address public pendingAdmin;

	uint256 public stepdown;
	uint256 public rewards;
	uint256 public supply;

	event Mint(address indexed sender, uint256 weekly, uint256 circulatingSupply, uint256 circulatingEmission);

	constructor(InitializationParams memory params) {
		stepdown = params.stepdown;
		rewards = params.rewards;
		supply = params.supply;
		initializer = msg.sender;
		admin = msg.sender;
		voter = IVoter(params.voter);
		ve = IVotingEscrow(params.ve);
		alcx = IERC20Mintable(params.alcx);
		rewardsDistributor = IRewardsDistributor(params.rewardsDistributor);
		activePeriod = ((block.timestamp + WEEK) / WEEK) * WEEK;
	}

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

	// calculate circulating supply as total token supply - locked supply
	function circulatingSupply() public view returns (uint256) {
		return alcx.totalSupply() - ve.totalSupply();
	}

	function weeklyEmission() public view returns (uint256) {
		return rewards - stepdown;
	}

	function weeklyEmissionRate() public view returns (uint256) {
		return (rewards / (rewards + stepdown)) * 1e18 * 52e18;
	}

	function circulatingEmissions() public view returns (uint256) {
		return supply;
	}

	// calculate inflation and adjust ve balances accordingly
	// this should adjust the balances of veALCX holders aka gALCX?
	// think we should move the logic for veALCX distrubtion to the rewards distributor
	// function veGrowth(uint256 _minted) public view returns (uint256) {
	// 	uint256 _veTotal = ve.totalSupply();
	// 	uint256 _alcxTotal = alcx.totalSupply();
	// 	return (((((_minted * _veTotal) / _alcxTotal) * _veTotal) / _alcxTotal) * _veTotal) / _alcxTotal / 2;
	// }

	// update period can only be called once per cycle (1 week)
	function updatePeriod() external returns (uint256) {
		uint256 _period = activePeriod;
		if (block.timestamp >= _period + WEEK && initializer == address(0)) {
			// only trigger if new week
			_period = (block.timestamp / WEEK) * WEEK;
			activePeriod = _period;
			weekly = weeklyEmission();

			// uint256 _growth = veGrowth(weekly);
			uint256 _balanceOf = alcx.balanceOf(address(this));
			if (_balanceOf < weekly) {
				alcx.mint(address(this), weekly - _balanceOf);
			}

			// Set rewards for next epoch
			rewards -= stepdown;

			// Adjust updated emissions total
			supply += rewards;

			// Once we reach the plateau stepdown becomes 0
			if (rewards <= TAIL) {
				stepdown = 0;
			}

			// require(alcx.transfer(address(rewardsDistributor), _growth));
			rewardsDistributor.checkpoint_token(); // checkpoint token balance that was just minted in rewards distributor
			rewardsDistributor.checkpoint_total_supply(); // checkpoint supply

			alcx.approve(address(voter), weekly);
			voter.notifyRewardAmount(weekly);

			emit Mint(msg.sender, weekly, circulatingSupply(), circulatingEmissions());
		}
		return _period;
	}
}
