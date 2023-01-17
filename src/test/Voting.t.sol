// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract VotingTest is BaseTest {
    function setUp() public {
        setupContracts(block.timestamp);
    }

    // Check ALCX balances increase in distributor and voter over an epoch
    function testEpochRewards() public {
        uint256 distributorBal = alcx.balanceOf(address(distributor));
        uint256 voterBal = alcx.balanceOf(address(voter));

        assertEq(distributorBal, 0);
        assertEq(voterBal, 0);

        hevm.warp(block.timestamp + 2 weeks);
        hevm.roll(block.number + 1);

        minter.updatePeriod();

        assertGt(alcx.balanceOf(address(distributor)), distributorBal);
        assertGt(alcx.balanceOf(address(voter)), voterBal);
    }

    function testSameEpochVoteOrReset() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        hevm.startPrank(admin);

        uint256 period = minter.activePeriod();

        // Move forward a week relative to period
        hevm.warp(period + 1 weeks);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;
        voter.vote(tokenId, pools, weights, 0);

        // Move forward half epoch relative to period
        hevm.warp(period + 1 weeks / 2);

        // Voting again fails
        pools[0] = alUSDPool;
        hevm.expectRevert(abi.encodePacked("TOKEN_ALREADY_VOTED_THIS_EPOCH"));
        voter.vote(tokenId, pools, weights, 0);

        // Resetting fails
        hevm.expectRevert(abi.encodePacked("TOKEN_ALREADY_VOTED_THIS_EPOCH"));
        voter.reset(tokenId);

        hevm.stopPrank();
    }

    function testNextEpochVoteOrReset() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        hevm.startPrank(admin);

        hevm.warp(block.timestamp + 1 weeks);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        voter.vote(tokenId, pools, weights, 0);

        // Next epoch
        hevm.warp(block.timestamp + 1 weeks);

        // New vote succeeds
        pools[0] = alUSDPool;
        voter.vote(tokenId, pools, weights, 0);

        // Next epoch
        hevm.warp(block.timestamp + 1 weeks);

        // Resetting succeeds
        voter.reset(tokenId);

        hevm.stopPrank();
    }

    // veALCX holders should be able to accrue their unclaimed mana over epochs
    function testAccrueMana() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        hevm.startPrank(admin);

        uint256 claimedBalance = mana.balanceOf(admin);
        uint256 unclaimedBalance = veALCX.unclaimedMana(tokenId);

        assertEq(claimedBalance, 0);
        assertEq(unclaimedBalance, 0);

        voter.reset(tokenId);

        unclaimedBalance = veALCX.unclaimedMana(tokenId);

        // Claimed balance is equal to the amount able to be claimed
        assertEq(unclaimedBalance, veALCX.claimableMana(tokenId));

        hevm.warp(block.timestamp + 1 weeks);

        voter.reset(tokenId);

        // Add this voting periods claimable mana to the unclaimed balance
        unclaimedBalance += veALCX.claimableMana(tokenId);

        // The unclaimed balance should equal the total amount of unclaimed mana
        assertEq(unclaimedBalance, veALCX.unclaimedMana(tokenId));

        hevm.stopPrank();
    }

    // veALCX holder should be able to mint mana they have accrued
    function testMintMana() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        hevm.startPrank(admin);

        uint256 claimedBalance = mana.balanceOf(admin);
        uint256 unclaimedBalance = veALCX.unclaimedMana(tokenId);

        assertEq(claimedBalance, 0);
        assertEq(unclaimedBalance, 0);

        hevm.expectRevert(abi.encodePacked("amount greater than unclaimed balance"));
        veALCX.claimMana(tokenId, TOKEN_1);

        voter.reset(tokenId);

        claimedBalance = veALCX.unclaimedMana(tokenId);

        veALCX.claimMana(tokenId, claimedBalance);

        unclaimedBalance = veALCX.unclaimedMana(tokenId);

        assertEq(unclaimedBalance, 0);
        assertEq(mana.balanceOf(admin), claimedBalance);

        hevm.stopPrank();
    }

    // veALCX holders can boost their vote with unclaimed mana up to a maximum amount
    function testBoostVoteWithMana() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        hevm.startPrank(admin);

        hevm.warp(block.timestamp + 1 weeks);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        uint256 claimableMana = veALCX.claimableMana(tokenId);
        uint256 votingWeight = veALCX.balanceOfToken(tokenId);

        uint256 maxBoostAmount = voter.maxVotingPower(tokenId);

        uint256 maxManaAmount = voter.maxManaBoost(tokenId);

        // Max boost amount should be the voting weight plus the boost multiplier
        assertEq(maxBoostAmount, votingWeight + maxManaAmount);

        // Vote should revert if attempting to boost more than the allowed amount
        hevm.expectRevert(abi.encodePacked("cannot exceed max boost"));
        voter.vote(tokenId, pools, weights, claimableMana);

        // Vote with the max boost amount
        voter.vote(tokenId, pools, weights, maxManaAmount);

        // Get weight used from boosting with mana
        uint256 usedWeight = voter.usedWeights(tokenId);

        // Used weight should be greater when boosting with unused mana
        assertGt(usedWeight, votingWeight);

        uint256 unclaimedMana = veALCX.unclaimedMana(tokenId);

        // Unclaimed mana balance should be remainaing mana not used to boost
        assertEq(unclaimedMana, claimableMana - maxManaAmount);

        hevm.stopPrank();
    }

    // Votes cannot be boosted with insufficient claimable mana balance
    function testCannotBoostVote() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        hevm.startPrank(admin);

        hevm.warp(block.timestamp + 1 weeks);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        uint256 claimableMana = veALCX.claimableMana(tokenId);

        // Vote with insufficient claimable mana balance
        hevm.expectRevert(abi.encodePacked("insufficient claimable MANA balance"));
        voter.vote(tokenId, pools, weights, claimableMana + 1);

        hevm.stopPrank();
    }

    // veALCX holder with max lock enabled should have constant max voting power
    function testMaxLockVotingPower() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, 0, true);

        hevm.startPrank(admin);

        uint256 maxVotingPower = getMaxVotingPower(TOKEN_1, veALCX.lockEnd(tokenId));

        uint256 votingPower1 = veALCX.balanceOfToken(tokenId);

        assertEq(votingPower1, maxVotingPower);

        hevm.warp(block.timestamp + 5 weeks);

        minter.updatePeriod();

        uint256 votingPower2 = veALCX.balanceOfToken(tokenId);

        // Voting power should remain the same with max lock enabled
        assertEq(votingPower1, votingPower2);

        // Disable max lock
        veALCX.updateUnlockTime(tokenId, 0, false);

        hevm.warp(block.timestamp + 5 weeks);

        uint256 votingPower3 = veALCX.balanceOfToken(tokenId);

        // Disabling max lock should start the voting power decay
        assertLt(votingPower3, votingPower2);

        hevm.stopPrank();
    }

    // veALCX voting power should decay to veALCX amount
    function testVotingPowerDecay() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, 1 weeks, false);

        hevm.startPrank(admin);

        hevm.warp(block.timestamp + 2 weeks);

        uint256 balance = veALCX.balanceOfToken(tokenId);

        // Voting power remains at 1 when lock is expired
        hevm.expectRevert(abi.encodePacked("Cannot add to expired lock. Withdraw"));
        veALCX.increaseAmount(tokenId, TOKEN_1);
        assertEq(balance, 0);

        hevm.stopPrank();
    }
}
