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
        uint256 tokenId1 = createVeAlcx(beef, TOKEN_1, MAXTIME, false);
        address bribeAddress = voter.bribes(address(sushiGauge));

        // BAL balance starts equal
        assertEq(IERC20(bal).balanceOf(admin), IERC20(bal).balanceOf(beef));

        minter.updatePeriod();

        // Add BAL bribes to sushi pool
        createThirdPartyBribe(bribeAddress, bal, TOKEN_100K);

        hevm.startPrank(admin);

        address[] memory pools = new address[](1);
        pools[0] = sushiPoolAddress;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        address[] memory bribes = new address[](1);
        bribes[0] = address(bribeAddress);
        address[][] memory tokens = new address[][](2);
        tokens[0] = new address[](1);
        tokens[0][0] = bal;

        uint256 claimableMana = veALCX.claimableMana(tokenId);
        uint256 votingWeight = veALCX.balanceOfToken(tokenId);
        uint256 maxBoostAmount = voter.maxVotingPower(tokenId);
        uint256 maxManaAmount = voter.maxManaBoost(tokenId);

        // Max boost amount should be the voting weight plus the boost multiplier
        assertEq(maxBoostAmount, votingWeight + maxManaAmount);

        // Vote should revert if attempting to boost more than the allowed amount
        hevm.expectRevert(abi.encodePacked("cannot exceed max boost"));
        voter.vote(tokenId, pools, weights, claimableMana);

        hevm.stopPrank();

        // Vote with the max boost amount
        hevm.prank(admin);
        voter.vote(tokenId, pools, weights, maxManaAmount);

        hevm.prank(beef);
        voter.vote(tokenId1, pools, weights, 0);

        // Used weight should be greater when boosting with unused mana
        assertGt(voter.usedWeights(tokenId), votingWeight);

        // Token boosting with MANA should have a higher used weight
        assertGt(voter.usedWeights(tokenId), voter.usedWeights(tokenId1));

        // Reach the end of the epoch
        hevm.warp(block.timestamp + 2 weeks);

        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId);

        hevm.prank(beef);
        voter.claimBribes(bribes, tokens, tokenId1);

        // Accout with boosted vote should capture more bribes
        assertGt(IERC20(bal).balanceOf(admin), IERC20(bal).balanceOf(beef));
    }

    function testBribes() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        address bribeAddress = voter.bribes(address(sushiGauge));
        uint256 rewardsLength = sushiGauge.rewardsListLength();

        // Add BAL bribes to sushiGauge
        createThirdPartyBribe(bribeAddress, bal, TOKEN_100K);

        uint256 bribeBalance = IERC20(bal).balanceOf(bribeAddress);

        // Epoch start should equal the current block.timestamp rounded to a week
        assertEq(block.timestamp - (block.timestamp % (7 days)), IBribe(bribeAddress).getEpochStart(block.timestamp));

        // Rewards list should increase after adding bribe
        assertEq(sushiGauge.rewardsListLength(), rewardsLength + 1);

        // Bribe contract should increase in bribe token balance
        assertEq(TOKEN_100K, bribeBalance);

        address[] memory pools = new address[](1);
        pools[0] = sushiPoolAddress;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        address[] memory bribes = new address[](1);
        bribes[0] = address(bribeAddress);
        address[][] memory tokens = new address[][](2);
        tokens[0] = new address[](1);
        tokens[0][0] = bal;

        hevm.prank(admin);
        voter.vote(tokenId, pools, weights, 0);

        // Reach the end of the epoch
        hevm.warp(block.timestamp + 2 weeks);

        uint256 earnedBribes = IBribe(bribeAddress).earned(bal, tokenId);
        uint256 priorBalanceIndex = IBribe(bribeAddress).getPriorBalanceIndex(tokenId, block.timestamp);
        uint256 priorSupply = IBribe(bribeAddress).getPriorSupplyIndex(block.timestamp);

        // Prior balance and supply should be zero since this is the first epoch for this voter
        assertEq(priorBalanceIndex, 0);
        assertEq(priorSupply, 0);

        // Earned bribes should be all bribes
        assertEq(earnedBribes, TOKEN_100K);

        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId);

        // The voter should capture all earned bribes
        assertEq(IERC20(bal).balanceOf(admin), earnedBribes);

        // Bribe address balance should be depleted by earned amount
        assertEq(bribeBalance - earnedBribes, IERC20(bal).balanceOf(bribeAddress));
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
