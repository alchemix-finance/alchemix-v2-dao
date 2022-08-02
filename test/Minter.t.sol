// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/console2.sol";
import { DSTest } from "ds-test/test.sol";

import { DSTestPlus } from "./utils/DSTestPlus.sol";
import { Minter, InitializationParams } from "../src/Minter.sol";
import { IERC20Mintable } from "../src/interfaces/IERC20Mintable.sol";
import { IVotingEscrow } from "../src/interfaces/IVotingEscrow.sol";
import { IRewardsDistributor } from "../src/interfaces/IRewardsDistributor.sol";
import { Voter } from "../src/Voter.sol";
import { PairFactory } from "../src/factories/PairFactory.sol";
import { GaugeFactory } from "../src/factories/GaugeFactory.sol";
import { BribeFactory } from "../src/factories/BribeFactory.sol";

contract MinterTest is DSTestPlus {
	IERC20Mintable public alcx = IERC20Mintable(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
	IVotingEscrow public veALCX = IVotingEscrow(address(alcx));
	IRewardsDistributor public rewardsDistributor = IRewardsDistributor(address(veALCX));
	Voter voter;
	PairFactory pairFactory;
	GaugeFactory gaugeFactory;
	BribeFactory bribeFactory;
	Minter minter;
	uint256 supply = 1793678 * 10e18;
	uint256 rewards = 12724 * 10e18;
	uint256 stepdown = 130 * 10e18;

	function setup() public {
		pairFactory = new PairFactory();
		gaugeFactory = new GaugeFactory(address(pairFactory));
		bribeFactory = new BribeFactory();
		voter = new Voter(address(veALCX), address(gaugeFactory), address(bribeFactory));

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
	}

	function testWeeklyEmissions() external {
		console2.log("here");
	}
}
