// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract VotingTest is BaseTest {
    uint256 depositAmount = 999 ether;
    uint256 lockTime = 30 days;

    function setUp() public {
        setupBaseTest(block.timestamp);

        hevm.startPrank(admin);

        IERC20(bpt).approve(address(veALCX), TOKEN_1);
        veALCX.createLock(TOKEN_1, MAXTIME, false);

        uint256 maxVotingPower = getMaxVotingPower(TOKEN_1, veALCX.lockEnd(1));

        voter.createGauge(alETHPool, IVoter.GaugeType.Staking);

        hevm.roll(block.number + 1);

        assertEq(veALCX.balanceOfToken(1), maxVotingPower);
        assertEq(IERC20(bpt).balanceOf(address(veALCX)), TOKEN_1);

        assertEq(veALCX.ownerOf(1), admin);

        hevm.roll(block.number + 1);

        // Check ALCX balances increase in distributor and voter over an epoch
        uint256 distributorBal = alcx.balanceOf(address(distributor));
        uint256 voterBal = alcx.balanceOf(address(voter));
        assertEq(distributorBal, 0);
        assertEq(voterBal, 0);

        hevm.warp(block.timestamp + 86400 * 14);
        hevm.roll(block.number + 1);

        minter.updatePeriod();
        assertGt(alcx.balanceOf(address(distributor)), distributorBal);
        assertGt(alcx.balanceOf(address(voter)), voterBal);
        hevm.stopPrank();
    }

    function testSameEpochVoteOrReset() public {
        hevm.startPrank(admin);

        uint256 period = minter.activePeriod();

        // Move forward a week relative to period
        hevm.warp(period + 1 weeks);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;
        voter.vote(1, pools, weights, 0);

        // Move forward half epoch relative to period
        hevm.warp(period + 1 weeks / 2);

        // Voting again fails
        pools[0] = alUSDPool;
        hevm.expectRevert(abi.encodePacked("TOKEN_ALREADY_VOTED_THIS_EPOCH"));
        voter.vote(1, pools, weights, 0);

        // Resetting fails
        hevm.expectRevert(abi.encodePacked("TOKEN_ALREADY_VOTED_THIS_EPOCH"));
        voter.reset(1);

        hevm.stopPrank();
    }

    function testNextEpochVoteOrReset() public {
        hevm.startPrank(admin);

        hevm.warp(block.timestamp + 1 weeks);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        voter.vote(1, pools, weights, 0);

        // Next epoch
        hevm.warp(block.timestamp + 1 weeks);

        // New vote succeeds
        pools[0] = alUSDPool;
        voter.vote(1, pools, weights, 0);

        // Next epoch
        hevm.warp(block.timestamp + 1 weeks);

        // Resetting succeeds
        voter.reset(1);

        hevm.stopPrank();
    }

    // veALCX holders should be able to accrue their unclaimed mana over epochs
    function testAccrueMana() public {
        hevm.startPrank(admin);

        uint256 claimedBalance = MANA.balanceOf(admin);
        uint256 unclaimedBalance = veALCX.unclaimedMana(1);

        assertEq(claimedBalance, 0);
        assertEq(unclaimedBalance, 0);

        voter.reset(1);

        unclaimedBalance = veALCX.unclaimedMana(1);

        // Claimed balance is equal to the amount able to be claimed
        assertEq(unclaimedBalance, veALCX.claimableMana(1));

        hevm.warp(block.timestamp + 1 weeks);

        voter.reset(1);

        // Add this voting periods claimable mana to the unclaimed balance
        unclaimedBalance += veALCX.claimableMana(1);

        // The unclaimed balance should equal the total amount of unclaimed mana
        assertEq(unclaimedBalance, veALCX.unclaimedMana(1));

        hevm.stopPrank();
    }

    // veALCX holder should be able to mint mana they have accrued
    function testMintMana() public {
        hevm.startPrank(admin);

        uint256 claimedBalance = MANA.balanceOf(admin);
        uint256 unclaimedBalance = veALCX.unclaimedMana(1);

        assertEq(claimedBalance, 0);
        assertEq(unclaimedBalance, 0);

        hevm.expectRevert(abi.encodePacked("amount greater than unclaimed balance"));
        veALCX.claimMana(1, TOKEN_1);

        voter.reset(1);

        claimedBalance = veALCX.unclaimedMana(1);

        veALCX.claimMana(1, claimedBalance);

        unclaimedBalance = veALCX.unclaimedMana(1);

        assertEq(unclaimedBalance, 0);
        assertEq(MANA.balanceOf(admin), claimedBalance);

        hevm.stopPrank();
    }

    // veALCX holders can boost their vote with unclaimed MANA up to a maximum amount
    function testBoostVoteWithMana() public {
        hevm.startPrank(admin);

        hevm.warp(block.timestamp + 1 weeks);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        uint256 claimableMana = veALCX.claimableMana(1);
        uint256 votingWeight = veALCX.balanceOfToken(1);

        uint256 maxBoostAmount = voter.maxVotingPower(1);

        uint256 maxManaAmount = voter.maxManaBoost(1);

        // Max boost amount should be the voting weight plus the boost multiplier
        assertEq(maxBoostAmount, votingWeight + maxManaAmount);

        // Vote should revert if attempting to boost more than the allowed amount
        hevm.expectRevert(abi.encodePacked("cannot exceed max boost"));
        voter.vote(1, pools, weights, claimableMana);

        // Vote with the max boost amount
        voter.vote(1, pools, weights, maxManaAmount);

        // Get weight used from boosting with MANA
        uint256 usedWeight = voter.usedWeights(1);

        // Used weight should be greater when boosting with unused MANA
        assertGt(usedWeight, votingWeight);

        uint256 unclaimedMana = veALCX.unclaimedMana(1);

        // Unclaimed mana balance should be remainaing mana not used to boost
        assertEq(unclaimedMana, claimableMana - maxManaAmount);

        hevm.stopPrank();
    }

    // Votes cannot be boosted with insufficient claimable MANA balance
    function testCannotBoostVote() public {
        hevm.startPrank(admin);

        hevm.warp(block.timestamp + 1 weeks);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        uint256 claimableMana = veALCX.claimableMana(1);

        // Vote with insufficient claimable MANA balance
        hevm.expectRevert(abi.encodePacked("insufficient claimable MANA balance"));
        voter.vote(1, pools, weights, claimableMana + 1);

        hevm.stopPrank();
    }

    // veALCX holder with max lock enabled should have constant max voting power
    function testMaxLockVotingPower() public {
        hevm.startPrank(admin);

        IERC20(bpt).approve(address(veALCX), TOKEN_1);
        veALCX.createLock(TOKEN_1, 0, true);

        uint256 maxVotingPower = getMaxVotingPower(TOKEN_1, veALCX.lockEnd(2));

        uint256 votingPower1 = veALCX.balanceOfToken(2);

        assertEq(votingPower1, maxVotingPower);

        hevm.warp(block.timestamp + 5 weeks);

        minter.updatePeriod();

        uint256 votingPower2 = veALCX.balanceOfToken(2);

        // Voting power should remain the same with max lock enabled
        assertEq(votingPower1, votingPower2);

        // Disable max lock
        veALCX.updateUnlockTime(2, 0, false);

        hevm.warp(block.timestamp + 5 weeks);

        uint256 votingPower3 = veALCX.balanceOfToken(2);

        // Disabling max lock should start the voting power decay
        assertLt(votingPower3, votingPower2);

        hevm.stopPrank();
    }

    // veALCX voting power should decay to veALCX amount
    function testVotingPowerDecay() public {
        hevm.startPrank(admin);

        IERC20(bpt).approve(address(veALCX), TOKEN_1);
        veALCX.createLock(TOKEN_1, 1 weeks, false);

        hevm.warp(block.timestamp + 2 weeks);

        uint256 balance = veALCX.balanceOfToken(2);

        // Voting power remains at 1 when lock is expired
        hevm.expectRevert(abi.encodePacked("Cannot add to expired lock. Withdraw"));
        veALCX.increaseAmount(2, TOKEN_1);
        assertEq(balance, 0);

        hevm.stopPrank();
    }
}
