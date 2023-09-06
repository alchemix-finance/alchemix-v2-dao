// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract VotingTest is BaseTest {
    function setUp() public {
        setupContracts(block.timestamp);
    }

    // Check ALCX balances increase in distributor and voter over an epoch
    function testEpochRewards() public {
        uint256 period = minter.activePeriod();

        uint256 distributorBal1 = alcx.balanceOf(address(distributor));
        uint256 voterBal1 = alcx.balanceOf(address(voter));

        assertEq(distributorBal1, 0);
        assertEq(voterBal1, 0);

        hevm.warp(period + nextEpoch);
        hevm.roll(block.number + 1);

        minter.updatePeriod();

        uint256 distributorBal2 = alcx.balanceOf(address(distributor));
        uint256 voterBal2 = alcx.balanceOf(address(voter));

        assertGt(distributorBal2, distributorBal1, "distributor balance should increase");
        // Voter has no balance since there have been no votes
        assertEq(voterBal2, voterBal1, "voter balance should not increase without votes");

        // Create a veALCX token and vote to trigger voter rewards
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        address[] memory pools = new address[](1);
        pools[0] = sushiPoolAddress;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;
        address[] memory gauges = new address[](1);
        gauges[0] = address(sushiGauge);

        hevm.warp(block.timestamp + nextEpoch);

        hevm.prank(admin);
        voter.vote(tokenId, pools, weights, 0);

        minter.updatePeriod();

        uint256 distributorBal3 = alcx.balanceOf(address(distributor));
        uint256 voterBal3 = alcx.balanceOf(address(voter));

        assertGt(distributorBal3, distributorBal2, "distributor balance should continue to increase");
        assertGt(voterBal3, voterBal2, "voter balance should increase with votes");
    }

    function testEarlyClaiming() public {
        uint256 period = minter.activePeriod();

        // Create a veALCX token and vote to trigger voter rewards
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        address bribeAddress = voter.bribes(address(sushiGauge));
        createThirdPartyBribe(bribeAddress, bal, TOKEN_100K);

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

        uint256 bribeBalance1 = IERC20(bal).balanceOf(admin);
        uint256 rewardsBalance1 = IERC20(alcx).balanceOf(admin);

        assertEq(bribeBalance1, 0, "bribe balance should be 0");

        hevm.startPrank(admin);
        hevm.expectRevert(abi.encodePacked("no rewards to claim"));
        voter.claimBribes(bribes, tokens, tokenId);
        distributor.claim(tokenId, false);
        hevm.stopPrank();

        uint256 bribeBalance2 = IERC20(bal).balanceOf(admin);
        uint256 rewardsBalance2 = IERC20(alcx).balanceOf(admin);

        // Claiming bribes and rewards before an epoch results in no rewards
        assertEq(bribeBalance2, 0, "bribe balance should not change");
        assertEq(rewardsBalance2, rewardsBalance1, "rewards balance should not change");

        // Move forward a week relative to period
        hevm.warp(period + nextEpoch);
        minter.updatePeriod();

        hevm.startPrank(admin);
        voter.claimBribes(bribes, tokens, tokenId);
        distributor.claim(tokenId, false);
        hevm.stopPrank();

        uint256 bribeBalance3 = IERC20(bal).balanceOf(admin);
        uint256 rewardsBalance3 = IERC20(alcx).balanceOf(admin);

        assertGt(bribeBalance3, bribeBalance2, "bribe balance should increase");
        assertGt(rewardsBalance3, rewardsBalance2, "rewards balance should increase");
    }

    function testSameEpochVoteOrReset() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        hevm.startPrank(admin);

        uint256 period = minter.activePeriod();

        // Move forward a week relative to period
        hevm.warp(period + nextEpoch);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;
        voter.vote(tokenId, pools, weights, 0);

        // Move forward half epoch relative to period
        hevm.warp(period + nextEpoch / 2);

        // Voting again fails
        pools[0] = alUSDPool;
        hevm.expectRevert(abi.encodePacked("TOKEN_ALREADY_VOTED_THIS_EPOCH"));
        voter.vote(tokenId, pools, weights, 0);

        // Resetting fails
        hevm.expectRevert(abi.encodePacked("TOKEN_ALREADY_VOTED_THIS_EPOCH"));
        voter.reset(tokenId);

        hevm.stopPrank();
    }

    function testInvalidGauge() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        hevm.startPrank(admin);

        uint256 period = minter.activePeriod();

        // Move forward a week relative to period
        hevm.warp(period + nextEpoch);

        address[] memory pools = new address[](1);
        pools[0] = dai;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        hevm.expectRevert(abi.encodePacked("cannot vote for dead gauge"));
        voter.vote(tokenId, pools, weights, 0);

        pools[0] = alUsdPoolAddress;
        voter.killGauge(voter.gauges(alUsdPoolAddress));

        hevm.expectRevert(abi.encodePacked("cannot vote for dead gauge"));
        voter.vote(tokenId, pools, weights, 0);

        hevm.stopPrank();
    }

    function testNextEpochVoteOrReset() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        hevm.startPrank(admin);

        hevm.warp(block.timestamp + nextEpoch);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        voter.vote(tokenId, pools, weights, 0);

        address[] memory poolVote = voter.getPoolVote(tokenId);
        assertEq(poolVote[0], alETHPool);

        // Next epoch
        hevm.warp(block.timestamp + nextEpoch);

        // New vote succeeds
        pools[0] = sushiPoolAddress;
        voter.vote(tokenId, pools, weights, 0);

        poolVote = voter.getPoolVote(tokenId);
        assertEq(poolVote[0], sushiPoolAddress);

        // Next epoch
        hevm.warp(block.timestamp + nextEpoch);

        voter.poke(tokenId);

        // Pool vote should remain the same after poke
        poolVote = voter.getPoolVote(tokenId);
        assertEq(poolVote[0], sushiPoolAddress);

        // Next epoch
        hevm.warp(block.timestamp + nextEpoch);

        // Resetting succeeds
        voter.reset(tokenId);

        hevm.stopPrank();
    }

    // veALCX holders should be able to accrue their unclaimed flux over epochs
    function testAccrueFlux() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        hevm.startPrank(admin);

        uint256 claimedBalance = flux.balanceOf(admin);
        uint256 unclaimedBalance = veALCX.unclaimedFlux(tokenId);

        assertEq(claimedBalance, 0);
        assertEq(unclaimedBalance, 0);

        voter.reset(tokenId);

        unclaimedBalance = veALCX.unclaimedFlux(tokenId);

        // Claimed balance is equal to the amount able to be claimed
        assertEq(unclaimedBalance, veALCX.claimableFlux(tokenId));

        hevm.warp(block.timestamp + nextEpoch);

        voter.reset(tokenId);

        // Add this voting periods claimable flux to the unclaimed balance
        unclaimedBalance += veALCX.claimableFlux(tokenId);

        // The unclaimed balance should equal the total amount of unclaimed flux
        assertEq(unclaimedBalance, veALCX.unclaimedFlux(tokenId));

        hevm.stopPrank();
    }

    // veALCX holder should be able to mint flux they have accrued
    function testMintFlux() public {
        hevm.expectRevert(abi.encodePacked("FluxToken: only minter"));
        FluxToken(flux).setMinter(address(admin));

        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        hevm.startPrank(admin);

        uint256 claimedBalance = flux.balanceOf(admin);
        uint256 unclaimedBalance = veALCX.unclaimedFlux(tokenId);

        assertEq(claimedBalance, 0);
        assertEq(unclaimedBalance, 0);

        hevm.expectRevert(abi.encodePacked("amount greater than unclaimed balance"));
        veALCX.claimFlux(tokenId, TOKEN_1);

        voter.reset(tokenId);

        claimedBalance = veALCX.unclaimedFlux(tokenId);

        veALCX.claimFlux(tokenId, claimedBalance);

        unclaimedBalance = veALCX.unclaimedFlux(tokenId);

        assertEq(unclaimedBalance, 0);
        assertEq(flux.balanceOf(admin), claimedBalance);

        hevm.stopPrank();
    }

    // veALCX holders can boost their vote with unclaimed flux up to a maximum amount
    function testBoostVoteWithFlux() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        uint256 tokenId1 = createVeAlcx(beef, TOKEN_1, MAXTIME, false);
        address bribeAddress = voter.bribes(address(sushiGauge));

        // BAL balance starts equal
        assertEq(IERC20(bal).balanceOf(admin), IERC20(bal).balanceOf(beef));

        // Add BAL bribes to sushi pool
        createThirdPartyBribe(bribeAddress, bal, TOKEN_100K);

        address[] memory pools = new address[](1);
        pools[0] = sushiPoolAddress;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        address[] memory bribes = new address[](1);
        bribes[0] = address(bribeAddress);
        address[][] memory tokens = new address[][](2);
        tokens[0] = new address[](1);
        tokens[0][0] = bal;

        uint256 votingWeight = veALCX.balanceOfToken(tokenId);
        uint256 maxFluxAmount = voter.maxFluxBoost(tokenId);
        uint256 fluxAccessable = veALCX.claimableFlux(tokenId) + veALCX.unclaimedFlux(tokenId);

        // Max boost amount should be the voting weight plus the boost multiplier
        assertEq(voter.maxVotingPower(tokenId), votingWeight + maxFluxAmount);

        hevm.prank(admin);
        // Voter should revert if attempting to boost more amount of flux they have accrued and can claim
        hevm.expectRevert(abi.encodePacked("insufficient FLUX to boost"));
        voter.vote(tokenId, pools, weights, fluxAccessable + 1);

        // Vote with the max boost amount
        hevm.prank(admin);
        voter.vote(tokenId, pools, weights, fluxAccessable);

        hevm.prank(beef);
        voter.vote(tokenId1, pools, weights, 0);

        // Used weight should be greater when boosting with unused flux
        assertGt(voter.usedWeights(tokenId), votingWeight, "should be greater when boosting");

        // Token boosting with FLUX should have a higher used weight
        assertGt(
            voter.usedWeights(tokenId),
            voter.usedWeights(tokenId1),
            "token boosting should have higher used weight"
        );

        // Reach the end of the epoch
        hevm.warp(block.timestamp + nextEpoch);

        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId);

        hevm.prank(beef);
        voter.claimBribes(bribes, tokens, tokenId1);

        // Accout with boosted vote should capture more bribes
        assertGt(IERC20(bal).balanceOf(admin), IERC20(bal).balanceOf(beef), "should capture more bribes");
    }

    // veALCX holders should be able to maintain their vote without re-voting each epoch
    function testPoke() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        hevm.warp(block.timestamp + nextEpoch);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        hevm.prank(admin);
        voter.vote(tokenId, pools, weights, 0);

        address[] memory poolVote = voter.getPoolVote(tokenId);
        assertEq(poolVote[0], alETHPool);

        // Next epoch
        hevm.warp(block.timestamp + nextEpoch);

        // Only approved or owner can call poke for a given tokenId
        hevm.expectRevert(abi.encodePacked("not approved or owner"));
        voter.poke(tokenId);

        hevm.prank(admin);
        voter.poke(tokenId);

        address[] memory poolVoteBefore = voter.getPoolVote(tokenId);

        hevm.prank(admin);
        voter.poke(tokenId);

        address[] memory poolVoteAfter = voter.getPoolVote(tokenId);

        // Calling poke multiple times should not inflate the voting balance
        assertEq(poolVoteBefore[0], poolVoteAfter[0], "voting balance inflated");

        // Last voted should be updated
        assertEq(voter.lastVoted(tokenId), block.timestamp, "last voted not updated");

        // Pool vote should remain the same after poke
        poolVote = voter.getPoolVote(tokenId);
        assertEq(poolVote[0], alETHPool);
    }

    // Test voting on gauges to earn third party bribes
    function testBribes() public {
        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        uint256 tokenId2 = createVeAlcx(beef, TOKEN_1, MAXTIME, false);
        uint256 initialTimestamp = block.timestamp;

        address bribeAddress = voter.bribes(address(sushiGauge));
        uint256 rewardsLength = IBribe(bribeAddress).rewardsListLength();

        // Add BAL bribes to sushiGauge
        createThirdPartyBribe(bribeAddress, bal, TOKEN_100K);

        // Tokens should have to be added to the whitelist before being able to bribe
        hevm.expectRevert(abi.encodePacked("bribe tokens must be whitelisted"));
        IBribe(bribeAddress).notifyRewardAmount(usdc, TOKEN_100K);

        uint256 rewardApplicable = IBribe(bribeAddress).lastTimeRewardApplicable(bal);

        assertEq(rewardApplicable, block.timestamp, "reward applicable should be current timestamp");

        // Bribe contract should increase in bribe token balance
        assertEq(TOKEN_100K, IERC20(bal).balanceOf(bribeAddress), "bribe contract missing bribes");

        // Epoch start should equal the current block.timestamp rounded to a week
        assertEq(block.timestamp - (block.timestamp % (7 days)), IBribe(bribeAddress).getEpochStart(block.timestamp));

        // Rewards list should increase after adding bribe
        assertEq(IBribe(bribeAddress).rewardsListLength(), rewardsLength + 1);

        address[] memory pools = new address[](1);
        pools[0] = sushiPoolAddress;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        address[] memory bribes = new address[](1);
        bribes[0] = address(bribeAddress);
        address[][] memory tokens = new address[][](2);
        tokens[0] = new address[](2);
        tokens[0][0] = bal;
        tokens[0][1] = aura;

        hevm.prank(admin);
        voter.vote(tokenId1, pools, weights, 0);

        // Claiming before the end of the epoch should not capture bribes
        assertEq(IERC20(bal).balanceOf(admin), 0, "admin bal balance not 0");
        assertEq(IERC20(aura).balanceOf(admin), 0, "admin aura balance not 0");
        assertEq(IERC20(bal).balanceOf(beef), 0, "beef bal balance not 0");
        assertEq(IERC20(aura).balanceOf(beef), 0, "beef aura balance not 0");

        // Adding a bribe to a gauge should increase the bribes list length
        // Should be able to add a bribe at any point in an epoch
        hevm.warp(block.timestamp + 6 days);
        createThirdPartyBribe(bribeAddress, aura, TOKEN_100K);
        assertEq(IBribe(bribeAddress).rewardsListLength(), rewardsLength + 2);

        hevm.prank(beef);
        voter.vote(tokenId2, pools, weights, 0);

        // Reach the end of the epoch
        hevm.warp(block.timestamp + nextEpoch);

        rewardApplicable = IBribe(bribeAddress).lastTimeRewardApplicable(bal);
        assertGt(block.timestamp, rewardApplicable, "reward applicable should be in the past");

        // Prior balance and supply should be zero since this is the first epoch for this voter
        assertEq(IBribe(bribeAddress).getPriorBalanceIndex(tokenId1, initialTimestamp), 0, "prior balance should be 0");
        assertEq(IBribe(bribeAddress).getPriorSupplyIndex(initialTimestamp), 0, "prior supply should be 0");

        // Earlier voter should earn more bribes
        assertGt(
            IBribe(bribeAddress).earned(bal, tokenId1),
            IBribe(bribeAddress).earned(bal, tokenId2),
            "earlier voter should earn more bal"
        );
        assertGt(
            IBribe(bribeAddress).earned(aura, tokenId1),
            IBribe(bribeAddress).earned(aura, tokenId2),
            "earlier voter should earn more aura"
        );

        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId1);

        hevm.prank(beef);
        voter.claimBribes(bribes, tokens, tokenId2);

        assertGt(
            IERC20(bal).balanceOf(admin) + IERC20(bal).balanceOf(beef),
            IERC20(bal).balanceOf(bribeAddress),
            "not all bal bribes were claimed"
        );
        assertGt(
            IERC20(aura).balanceOf(admin) + IERC20(aura).balanceOf(beef),
            IERC20(aura).balanceOf(bribeAddress),
            "not all aura bribes were claimed"
        );

        assertGt(IERC20(bal).balanceOf(admin), IERC20(bal).balanceOf(beef), "earlier voter should earn more bal");
        assertGt(IERC20(aura).balanceOf(admin), IERC20(aura).balanceOf(beef), "earlier voter should earn more aura");
        assertGt(
            IERC20(aura).balanceOf(beef),
            IERC20(aura).balanceOf(bribeAddress),
            "voters should deplete the bribes"
        );
        assertGt(
            IERC20(aura).balanceOf(beef),
            IERC20(aura).balanceOf(bribeAddress),
            "voters should deplete the bribes"
        );

        assertGt(
            TOKEN_100K * 2,
            IERC20(bal).balanceOf(admin) +
                IERC20(bal).balanceOf(beef) +
                IERC20(aura).balanceOf(admin) +
                IERC20(aura).balanceOf(beef),
            "bribes claimed should be less than bribes added"
        );
    }

    // Test impact of voting on bribes earned
    function testBribeClaiming() public {
        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        uint256 tokenId2 = createVeAlcx(beef, TOKEN_1, MAXTIME, false);
        uint256 tokenId3 = createVeAlcx(holder, TOKEN_1, MAXTIME, false);
        address bribeAddress = voter.bribes(address(sushiGauge));

        // Add BAL bribes to sushiGauge
        createThirdPartyBribe(bribeAddress, bal, TOKEN_100K);

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
        voter.vote(tokenId1, pools, weights, 0);

        hevm.warp(block.timestamp + 6 days);

        hevm.prank(beef);
        voter.vote(tokenId2, pools, weights, 0);

        hevm.prank(holder);
        voter.vote(tokenId3, pools, weights, 0);

        // Reach the end of the epoch
        hevm.warp(block.timestamp + nextEpoch);

        uint256 earnedBribes1 = IBribe(bribeAddress).earned(bal, tokenId1);
        uint256 earnedBribes2 = IBribe(bribeAddress).earned(bal, tokenId2);

        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId1);

        assertEq(IERC20(bal).balanceOf(admin), earnedBribes1, "admin should capture half of bribes");

        // Fast forward 5 epochs
        hevm.warp(block.timestamp + nextEpoch * 5);

        // Simulate time passing and other veALCX holders voting
        hevm.prank(admin);
        voter.vote(tokenId1, pools, weights, 0);

        hevm.prank(holder);
        voter.poke(tokenId3);

        minter.updatePeriod();

        hevm.warp(block.timestamp + nextEpoch);

        hevm.prank(beef);
        voter.claimBribes(bribes, tokens, tokenId2);

        hevm.prank(holder);
        voter.claimBribes(bribes, tokens, tokenId3);

        assertEq(IERC20(bal).balanceOf(beef), earnedBribes2, "user should capture old bribes");

        assertGt(
            IERC20(bal).balanceOf(holder),
            IERC20(bal).balanceOf(beef),
            "user who poked should capture more bribes"
        );
    }

    // Test impact of voting on bribes earned
    function testMultipleEpochBribeClaiming() public {
        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        uint256 tokenId2 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        address bribeAddress = voter.bribes(address(sushiGauge));

        // Add BAL bribes to sushiGauge
        createThirdPartyBribe(bribeAddress, bal, TOKEN_100K);

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
        voter.vote(tokenId1, pools, weights, 0);

        hevm.prank(admin);
        voter.vote(tokenId2, pools, weights, 0);

        uint256 earnedBribes0 = IBribe(bribeAddress).earned(bal, tokenId1);

        assertEq(earnedBribes0, 0, "no bribes should be earned yet");

        // Start second epoch
        hevm.warp(block.timestamp + nextEpoch);
        minter.updatePeriod();

        uint256 earnedBribes1 = IBribe(bribeAddress).earned(bal, tokenId1);

        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId1);

        // Claiming twice shouldn't work
        hevm.expectRevert(abi.encodePacked("no rewards to claim"));
        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId1);

        // Reset voting for tokenId1
        hevm.prank(admin);
        voter.reset(tokenId1);
        hevm.prank(admin);
        voter.reset(tokenId2);

        assertEq(earnedBribes1, TOKEN_100K / 2, "bribes from voting should be earned");
        assertEq(earnedBribes1, IERC20(bal).balanceOf(admin), "admin should receive bribes");

        // Start third epoch
        hevm.warp(block.timestamp + nextEpoch);
        minter.updatePeriod();

        uint256 earnedBribes2 = IBribe(bribeAddress).earned(bal, tokenId2);
        assertEq(earnedBribes2, earnedBribes1, "earned bribes from previous epoch should remain");

        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId2);

        assertEq(earnedBribes1 + earnedBribes2, IERC20(bal).balanceOf(admin), "admin should receive both bribes");

        // Start fourth epoch
        hevm.warp(block.timestamp + nextEpoch);
        minter.updatePeriod();

        // Add more bribes
        createThirdPartyBribe(bribeAddress, bal, TOKEN_100K);

        uint256 earnedBribes3 = IBribe(bribeAddress).earned(bal, tokenId2);

        assertEq(earnedBribes3, 0, "no bribes should be earned without voting");

        // Claiming shouldn't work when earned is 0
        hevm.expectRevert(abi.encodePacked("no rewards to claim"));
        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId1);

        // Participate in voting
        hevm.prank(admin);
        voter.vote(tokenId1, pools, weights, 0);

        // Start fifth epoch
        hevm.warp(block.timestamp + nextEpoch);
        minter.updatePeriod();

        uint256 earnedBribes4 = IBribe(bribeAddress).earned(bal, tokenId1);

        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId1);

        assertEq(
            earnedBribes1 + earnedBribes2 + earnedBribes4,
            IERC20(bal).balanceOf(admin),
            "admin should receive bribes"
        );
    }

    // Voting power should be dependent on epoch at which vote is cast
    function testVotingPower() public {
        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        uint256 tokenId2 = createVeAlcx(beef, TOKEN_1, MAXTIME, false);
        uint256 tokenId3 = createVeAlcx(dead, TOKEN_1, MAXTIME, false);

        uint256 votingPower1 = veALCX.balanceOfToken(tokenId1);
        uint256 votingPower2 = veALCX.balanceOfToken(tokenId2);
        assertEq(votingPower1, votingPower2, "voting power should be equal");

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        hevm.prank(admin);
        voter.vote(tokenId1, pools, weights, 0);

        uint256 usedWeight1 = voter.usedWeights(tokenId1);

        hevm.warp(block.timestamp + 6 days);

        hevm.prank(beef);
        voter.vote(tokenId2, pools, weights, 0);

        uint256 usedWeight2 = voter.usedWeights(tokenId1);

        assertEq(usedWeight1, usedWeight2, "used weight should be equal");

        hevm.warp(block.timestamp + 6 days);
        minter.updatePeriod();

        hevm.prank(dead);
        voter.vote(tokenId3, pools, weights, 0);

        uint256 usedWeight3 = voter.usedWeights(tokenId3);

        assertGt(usedWeight2, usedWeight3, "used weight should be greater in previous epoch");
    }

    // Votes cannot be boosted with insufficient FLUX to boost
    function testCannotBoostVote() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        hevm.startPrank(admin);

        hevm.warp(block.timestamp + nextEpoch);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        uint256 claimableFlux = veALCX.claimableFlux(tokenId);

        // Vote with insufficient FLUX to boost
        hevm.expectRevert(abi.encodePacked("insufficient FLUX to boost"));
        voter.vote(tokenId, pools, weights, claimableFlux + 1);

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

    // veALCX voting power should decay to 0
    function testVotingPowerDecay() public {
        // Kick off epoch cycle
        hevm.warp(block.timestamp + nextEpoch);
        minter.updatePeriod();

        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, 3 weeks, false);
        uint256 tokenId2 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        uint256[] memory tokens = new uint256[](2);
        tokens[0] = tokenId1;
        tokens[1] = tokenId2;

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        hevm.startPrank(admin);

        // Vote and record used weights
        voter.vote(tokenId1, pools, weights, 0);
        voter.vote(tokenId2, pools, weights, 0);
        uint256 usedWeight1 = voter.usedWeights(tokenId2);
        uint256 totalWeight1 = voter.totalWeight();

        // Move to the next epoch
        hevm.warp(block.timestamp + nextEpoch);
        minter.updatePeriod();

        // Move to when token1 expires
        hevm.warp(block.timestamp + 3 weeks);

        // Mock poking idle tokens to sync voting
        hevm.stopPrank();
        hevm.prank(voter.admin());
        voter.pokeIdleTokens(tokens);
        hevm.startPrank(admin);

        minter.updatePeriod();

        // tokenId1 represents user who voted once and expired
        uint256 usedWeight = voter.usedWeights(tokenId1);
        assertEq(usedWeight, 0, "used weight should be 0 for expired token");

        uint256 usedWeight2 = voter.usedWeights(tokenId2);
        uint256 totalWeight2 = voter.totalWeight();

        assertGt(usedWeight1, usedWeight2, "used weight should decrease");
        assertGt(totalWeight1, totalWeight2, "total weight should decrease");

        hevm.warp(block.timestamp + nextEpoch);
        minter.updatePeriod();

        uint256 balance = veALCX.balanceOfToken(tokenId1);

        // Voting power decays to 0
        hevm.expectRevert(abi.encodePacked("Cannot add to expired lock. Withdraw"));
        veALCX.depositFor(tokenId1, TOKEN_1);
        assertEq(balance, 0);

        // Voting with an expired token should revert
        hevm.expectRevert(abi.encodePacked("cannot vote with expired token"));
        voter.vote(tokenId1, pools, weights, 0);

        hevm.stopPrank();
    }

    function testAdminFunctions() public {
        assertEq(voter.initialized(), true, "voter not initialized");

        hevm.expectRevert(abi.encodePacked("already initialized"));
        voter.initialize(dai, admin);

        hevm.expectRevert(abi.encodePacked("not admin"));
        voter.setAdmin(devmsig);

        hevm.expectRevert(abi.encodePacked("not admin"));
        voter.setBoostMultiplier(1000);

        hevm.prank(address(timelockExecutor));
        voter.setAdmin(devmsig);

        hevm.expectRevert(abi.encodePacked("not pending admin"));
        voter.acceptAdmin();

        hevm.startPrank(devmsig);

        voter.acceptAdmin();
        voter.setBoostMultiplier(1000);

        voter.whitelist(dai);

        assertEq(voter.isWhitelisted(dai), true, "whitelisting failed");

        hevm.stopPrank();
    }
}
