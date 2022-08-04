// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/console2.sol";

import { DSTestPlus } from "./utils/DSTestPlus.sol";
import { Minter, InitializationParams } from "../src/Minter.sol";
import { IAlchemixToken } from "../src/interfaces/IAlchemixToken.sol";
import { IVotingEscrow } from "../src/interfaces/IVotingEscrow.sol";
import { IRewardsDistributor } from "../src/interfaces/IRewardsDistributor.sol";
import { Voter } from "../src/Voter.sol";

contract MinterTest is DSTestPlus {
	IAlchemixToken public alcx = IAlchemixToken(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
	IVotingEscrow public veALCX = IVotingEscrow(address(alcx));
	IRewardsDistributor public rewardsDistributor = IRewardsDistributor(address(veALCX));
	address constant admin = 0x8392F6669292fA56123F71949B52d883aE57e225;

	// TODO add emissions distributions to tests with voter contract
	Voter voter = Voter(address(0x000000000000000000000000000000000000dEaD));

	Minter minter;

	// Current emission values
	uint256 supply = 1793678 * 10e18;
	uint256 rewards = 12724 * 10e18;
	uint256 stepdown = 130 * 10e18;
	uint256 nextEpoch = 86400 * 14;
	uint256 epochsUntilTail = 80;
	uint256 supplyAtTail = 2392609 * 10e18;

	function setUp() public {
		InitializationParams memory params = InitializationParams(
			address(voter),
			address(veALCX),
			address(rewardsDistributor),
			address(alcx),
			supply,
			rewards,
			stepdown
		);

		minter = new Minter(params);

		// Give the minter role to the minter contract
		hevm.startPrank(admin, admin);
		alcx.grantRole(keccak256("MINTER"), address(minter));
		hevm.stopPrank();

		// Initialize minter
		minter.initialize();
	}

	// Test emissions for a single epoch
	function testEpochEmissions() external {
		// Set the block timestamp to be the next epoch
		hevm.warp(block.timestamp + nextEpoch);

		uint256 currentTotalEmissions = minter.circulatingEmissionsSupply();
		uint256 epochEmissions = minter.epochEmission();

		// Mint emissions for epoch
		minter.updatePeriod();

		uint256 totalAfterEpoch = minter.circulatingEmissionsSupply();
		emit log_named_uint("emissions after one epoch (ether)", totalAfterEpoch / 10e18);

		assertEq(totalAfterEpoch, currentTotalEmissions + epochEmissions);
	}

	// Test reaching emissions tail
	function testTailEmissions() external {
		// Mint emissions for the amount of epochs until tail emissions target
		for (uint8 i = 0; i <= epochsUntilTail; ++i) {
			hevm.warp(block.timestamp + nextEpoch);
			minter.updatePeriod();
		}

		uint256 tailRewards = minter.rewards();
		uint256 tailStepdown = minter.stepdown();
		uint256 tailEmissionSupply = minter.circulatingEmissionsSupply();
		emit log_named_uint("tail emissions supply (ether)", tailEmissionSupply / 10e18);

		// Assert rewards are the constant tail emissions value
		assertEq(tailRewards, minter.tailEmissionsRate());

		// Assert stepdown is 0 once tail emissions are reached
		assertEq(tailStepdown, 0);

		// Assert total emissions are the approximate target at the tail
		assertApproxEq(tailEmissionSupply, supplyAtTail, 17 * 10e18);
	}
}
