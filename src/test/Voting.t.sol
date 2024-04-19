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

        voter.distribute();

        deal(address(alcx), address(voter), TOKEN_100K);

        hevm.expectRevert(abi.encodePacked("not voter"));
        sushiGauge.notifyRewardAmount(TOKEN_100K);

        hevm.prank(address(voter));
        hevm.expectRevert(abi.encodePacked("zero amount"));
        sushiGauge.notifyRewardAmount(0);

        hevm.prank(address(voter));
        sushiGauge.notifyRewardAmount(TOKEN_100K);

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

        voter.distribute();

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
        voter.distribute();

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

        hevm.prank(voter.admin());
        hevm.expectRevert(abi.encodePacked("exists"));
        voter.createGauge(alUsdPoolAddress, IVoter.GaugeType.Passthrough);

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

    function testManageGauge() public {
        address emergencyCouncil = voter.emergencyCouncil();
        address gaugeAddress = voter.gauges(alUsdPoolAddress);

        bool isGaugeAlive = voter.isAlive(gaugeAddress);
        assertEq(isGaugeAlive, true, "gauge should be alive");

        hevm.expectRevert(abi.encodePacked("not emergency council"));
        voter.killGauge(gaugeAddress);

        hevm.prank(emergencyCouncil);
        voter.killGauge(gaugeAddress);

        hevm.prank(emergencyCouncil);
        hevm.expectRevert(abi.encodePacked("gauge already dead"));
        voter.killGauge(gaugeAddress);

        hevm.prank(beef);
        hevm.expectRevert(abi.encodePacked("not emergency council"));
        voter.reviveGauge(gaugeAddress);

        hevm.prank(emergencyCouncil);
        hevm.expectRevert(abi.encodePacked("invalid gauge"));
        voter.reviveGauge(beef);

        hevm.prank(emergencyCouncil);
        voter.reviveGauge(gaugeAddress);

        hevm.prank(emergencyCouncil);
        hevm.expectRevert(abi.encodePacked("gauge already alive"));
        voter.reviveGauge(gaugeAddress);
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

        hevm.stopPrank();

        // Resetting fails when not approved or owner
        hevm.prank(beef);
        hevm.expectRevert(abi.encodePacked("not approved or owner"));
        voter.reset(tokenId);

        // Resetting succeeds
        hevm.prank(admin);
        voter.reset(tokenId);
    }

    // veALCX holders should be able to accrue their unclaimed flux over epochs
    function testAccrueFlux() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        hevm.startPrank(admin);

        uint256 claimedBalance = flux.balanceOf(admin);
        uint256 unclaimedBalance = flux.getUnclaimedFlux(tokenId);

        assertEq(claimedBalance, 0);
        assertEq(unclaimedBalance, 0);

        voter.reset(tokenId);

        unclaimedBalance = flux.getUnclaimedFlux(tokenId);

        // Claimed balance is equal to the amount able to be claimed
        assertEq(unclaimedBalance, veALCX.claimableFlux(tokenId));

        hevm.warp(block.timestamp + nextEpoch);

        voter.reset(tokenId);

        // Add this voting periods claimable flux to the unclaimed balance
        unclaimedBalance += veALCX.claimableFlux(tokenId);

        // The unclaimed balance should equal the total amount of unclaimed flux
        assertEq(unclaimedBalance, flux.getUnclaimedFlux(tokenId));

        hevm.stopPrank();
    }

    // veALCX holder should be able to mint flux they have accrued
    function testMintFlux() public {
        hevm.expectRevert(abi.encodePacked("FluxToken: only minter"));
        flux.setMinter(address(admin));

        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        hevm.startPrank(admin);

        uint256 claimedBalance = flux.balanceOf(admin);
        uint256 unclaimedBalance = flux.getUnclaimedFlux(tokenId);

        assertEq(claimedBalance, 0, "claimed balance should be 0");
        assertEq(unclaimedBalance, 0, "unclaimed balance should be 0");

        hevm.expectRevert(abi.encodePacked("amount greater than unclaimed balance"));
        flux.claimFlux(tokenId, TOKEN_1);

        voter.reset(tokenId);

        claimedBalance = flux.getUnclaimedFlux(tokenId);

        flux.claimFlux(tokenId, claimedBalance);

        unclaimedBalance = flux.getUnclaimedFlux(tokenId);

        assertEq(unclaimedBalance, 0, "unclaimed balance should reset");
        assertEq(flux.balanceOf(admin), claimedBalance, "admin flux balance should increase");

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
        uint256 fluxAccessable = veALCX.claimableFlux(tokenId) + flux.getUnclaimedFlux(tokenId);

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

        // Bribe amount must be greater than 0
        hevm.expectRevert(abi.encodePacked("reward amount must be greater than 0"));
        IBribe(bribeAddress).notifyRewardAmount(usdc, 0);

        uint256 rewardApplicable = IBribe(bribeAddress).lastTimeRewardApplicable(bal);

        assertEq(rewardApplicable, block.timestamp, "reward applicable should be current timestamp");

        // Bribe contract should increase in bribe token balance
        assertEq(TOKEN_100K, IERC20(bal).balanceOf(bribeAddress), "bribe contract missing bribes");

        // Epoch start should equal the current block.timestamp rounded to a week
        assertEq(block.timestamp - (block.timestamp % (2 weeks)), IBribe(bribeAddress).getEpochStart(block.timestamp));

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
        assertEq(IBribe(bribeAddress).getPriorVotingIndex(initialTimestamp), 0, "prior voting should be 0");

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

    function testPriorVotingIndexZero() public {
        uint256 initialTimestamp = block.timestamp;

        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        address bribeAddress = voter.bribes(address(sushiGauge));

        // Prior index should be zero when nCheckpoints is zero
        uint256 priorIndex = IBribe(bribeAddress).getPriorVotingIndex(initialTimestamp);
        assertEq(priorIndex, 0, "prior voting index should be 0");

        uint256 earned = IBribe(bribeAddress).earned(address(alcx), tokenId1);
        assertEq(earned, 0, "earned should be 0 when there are no checkpoints for a token");

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

        // Fast forward epochs
        hevm.warp(block.timestamp + nextEpoch * 5);

        // Prior index should be zero when timestamp is before first checkpoint timestamp
        uint256 priorIndexNow = IBribe(bribeAddress).getPriorVotingIndex(initialTimestamp - nextEpoch * 5);
        assertEq(priorIndexNow, 0, "prior voting index should be 0");
    }

    // Test impact of voting on bribes earned
    function testBribeAccounting() public {
        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        uint256 tokenId2 = createVeAlcx(beef, TOKEN_1, MAXTIME, false);

        address bribeAddress = voter.bribes(address(sushiGauge));

        // Add BAL bribes to sushiGauge
        createThirdPartyBribe(bribeAddress, bal, TOKEN_100K);

        uint256 balanceStart = IERC20(bal).balanceOf(bribeAddress);

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

        // Fast forward epochs
        hevm.warp(block.timestamp + nextEpoch * 5);

        // Simulate other holders voting
        hevm.prank(beef);
        voter.vote(tokenId2, pools, weights, 0);

        voter.distribute();

        uint256 earnedBribes1 = IBribe(bribeAddress).earned(bal, tokenId1);
        uint256 earnedBribes2 = IBribe(bribeAddress).earned(bal, tokenId2);

        assertEq(earnedBribes1, balanceStart, "token1 should earn bribes");
        assertEq(earnedBribes2, 0, "token2 shouldn't earn bribes");

        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId1);

        hevm.prank(beef);
        hevm.expectRevert(abi.encodePacked("no rewards to claim"));
        voter.claimBribes(bribes, tokens, tokenId2);

        uint256 balanceEnd = IERC20(bal).balanceOf(bribeAddress);

        assertEq(balanceEnd, 0, "balance should be 0");

        assertEq(IERC20(bal).balanceOf(admin), balanceStart, "should capture all bribes");
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

        voter.distribute();

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
        hevm.warp(newEpoch());
        voter.distribute();

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
        hevm.warp(newEpoch());
        voter.distribute();

        uint256 earnedBribes2 = IBribe(bribeAddress).earned(bal, tokenId2);
        assertEq(earnedBribes2, earnedBribes1, "earned bribes from previous epoch should remain");

        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId2);

        assertEq(earnedBribes1 + earnedBribes2, IERC20(bal).balanceOf(admin), "admin should receive both bribes");

        // Start fourth epoch
        hevm.warp(newEpoch());
        voter.distribute();

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
        hevm.warp(newEpoch());
        voter.distribute();

        uint256 earnedBribes4 = IBribe(bribeAddress).earned(bal, tokenId1);

        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId1);

        assertEq(
            earnedBribes1 + earnedBribes2 + earnedBribes4,
            IERC20(bal).balanceOf(admin),
            "admin should receive bribes"
        );
    }

    function testGetRewardForOwner() public {
        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        address bribeAddress = voter.bribes(address(sushiGauge));

        // Add BAL bribes to sushiGauge
        createThirdPartyBribe(bribeAddress, bal, TOKEN_100K);

        address[] memory pools = new address[](1);
        pools[0] = sushiPoolAddress;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        address[] memory bribes = new address[](1);
        bribes[0] = address(bribeAddress);
        address[][] memory tokens = new address[][](1);
        tokens[0] = new address[](1);
        tokens[0][0] = bal;

        // in epoch i, user votes with balance x
        hevm.prank(admin);
        voter.vote(tokenId1, pools, weights, 0);

        // Start second epoch i+1
        hevm.warp(newEpoch());
        createThirdPartyBribe(bribeAddress, bal, TOKEN_100K);

        // Claim bribes from epoch i
        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId1);

        hevm.warp(newEpoch());
        hevm.prank(admin);
        hevm.expectRevert(abi.encodePacked("no rewards to claim"));
        voter.claimBribes(bribes, tokens, tokenId1);
    }

    function testBugTotalBribeWeights() public {
        // epoch i
        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        uint256 tokenId2 = createVeAlcx(beef, TOKEN_1, MAXTIME, false);

        address bribeAddress = voter.bribes(address(sushiGauge));

        // Add BAL bribes to sushiGauge
        createThirdPartyBribe(bribeAddress, bal, TOKEN_100K);

        uint256 balanceStart = IERC20(bal).balanceOf(bribeAddress);

        address[] memory pools = new address[](2);
        pools[0] = sushiPoolAddress;
        pools[1] = balancerPoolAddress;
        uint256[] memory weights = new uint256[](2);
        weights[0] = 2500;
        weights[1] = 2500;

        address[] memory bribes = new address[](1);
        bribes[0] = address(bribeAddress);
        address[][] memory tokens = new address[][](2);
        tokens[0] = new address[](1);
        tokens[0][0] = bal;

        hevm.prank(admin);
        voter.vote(tokenId1, pools, weights, 0);
        hevm.prank(beef);
        voter.vote(tokenId2, pools, weights, 0);

        assertEq(voter.usedWeights(tokenId1), voter.usedWeights(tokenId2), "used weights should be equal");

        // Fast forward i+1
        hevm.warp(IMinter(minter).activePeriod() + nextEpoch);
        voter.distribute();

        hevm.expectRevert(abi.encodePacked("can only distribute after period end"));
        voter.distribute();

        uint256 earnedBribes1 = IBribe(bribeAddress).earned(bal, tokenId1);
        uint256 earnedBribes2 = IBribe(bribeAddress).earned(bal, tokenId2);

        assertEq(earnedBribes1, balanceStart / 2, "token1 should earn bribes");
        assertEq(earnedBribes2, balanceStart / 2, "token2 should earn bribes");
        assertEq(earnedBribes1, earnedBribes2, "earnings should be equal");

        // epoch i+1, add bribes
        createThirdPartyBribe(bribeAddress, bal, TOKEN_100K);

        // epoch i+1, admin votes
        hevm.prank(admin);
        voter.vote(tokenId1, pools, weights, 0);

        assertLt(voter.usedWeights(tokenId1), voter.usedWeights(tokenId2), "weight of voter who voted should be less");

        // Fast forward i+2
        hevm.warp(IMinter(minter).activePeriod() + nextEpoch);
        voter.distribute();

        assertGt(
            IBribe(bribeAddress).earned(bal, tokenId1),
            IBribe(bribeAddress).earned(bal, tokenId2),
            "voting should earnings"
        );

        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId1);
        hevm.prank(beef);
        voter.claimBribes(bribes, tokens, tokenId2);

        // INTENDED BEHAVIOUR: the balance of the bribe should be 0
        uint256 balanceEnd = IERC20(bal).balanceOf(bribeAddress);
        assertEq(balanceEnd, 0, "bribe balance should be 0");

        // INTENDED BEHAVIOUR: the sum of the balances of the users is equal to the total bribes
        assertEq(
            IERC20(bal).balanceOf(admin) + IERC20(bal).balanceOf(beef),
            TOKEN_100K * 2,
            "balances should sum up to total"
        );
    }

    // Test bribes counted redudantly
    function testBugBribeClaiming() public {
        // ------------------- Start first epoch i

        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        address bribeAddress = voter.bribes(address(sushiGauge));

        // Add BAL bribes to sushiGauge
        createThirdPartyBribe(bribeAddress, bal, TOKEN_100K);

        address[] memory pools = new address[](1);
        pools[0] = sushiPoolAddress;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        address[] memory bribes = new address[](1);
        bribes[0] = address(bribeAddress);
        address[][] memory tokens = new address[][](1);
        tokens[0] = new address[](1);
        tokens[0][0] = bal;

        // in epoch i, admin votes
        hevm.prank(admin);
        voter.vote(tokenId1, pools, weights, 0);

        // ------------------- Start second epoch i+1
        hevm.warp(newEpoch());
        voter.distribute();

        uint256 earnedBribes1 = IBribe(bribeAddress).earned(bal, tokenId1);
        assertEq(earnedBribes1, TOKEN_100K, "bribes from voting should be earned");

        // in epoch i+1, admin claims bribes for epoch i
        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId1);

        assertEq(earnedBribes1, IERC20(bal).balanceOf(admin), "admin should receive bribes");

        // ------------------- Start third epoch i+3
        hevm.warp(newEpoch());
        voter.distribute();
        hevm.warp(newEpoch());
        voter.distribute();
        // in epoch i+3, admin votes again
        hevm.prank(admin);
        voter.vote(tokenId1, pools, weights, 0);

        // ------------------- Start fourth epoch i+4
        hevm.warp(newEpoch());
        voter.distribute();

        // INTENDED BEHAVIOUR: since the bribes for epoch i were already claimed in epoch i+1
        // --and no more bribes were notified after that-- there should be no available earnings at epoch i+4.
        uint256 earnedBribes1Again = IBribe(bribeAddress).earned(bal, tokenId1);
        assertEq(earnedBribes1Again, 0, "there should be no bribes for epoch i+4");

        // INTENDED BEHAVIOUR: since there are no bribes available, the claim function should revert with the message "no rewards to claim".
        hevm.expectRevert(abi.encodePacked("no rewards to claim"));
        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId1);
    }

    function testBugVotingSupply() public {
        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        uint256 tokenId2 = createVeAlcx(beef, TOKEN_1, MAXTIME, false);
        address bribeAddress = voter.bribes(address(sushiGauge));

        // Add BAL bribes to sushiGauge
        createThirdPartyBribe(bribeAddress, bal, TOKEN_100K);

        address[] memory pools = new address[](1);
        pools[0] = sushiPoolAddress;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        address[] memory bribes = new address[](1);
        bribes[0] = address(bribeAddress);
        address[][] memory tokens = new address[][](1);
        tokens[0] = new address[](1);
        tokens[0][0] = bal;

        // in epoch i, attacker votes with balance x
        hevm.prank(admin);
        voter.vote(tokenId1, pools, weights, 0);

        hevm.prank(beef);
        voter.vote(tokenId2, pools, weights, 0);

        // ------------------- Start second epoch i+1
        hevm.warp(newEpoch());
        createThirdPartyBribe(bribeAddress, bal, TOKEN_100K);

        // attacker calls Voter.distribute(), which triggers Bribe.resetVoting(), therefore setting totalVoting = 0.
        // the attacker votes again with balance x which triggers a new supply checkpoint which includes only attacker's vote x
        // Attacker calls Bribe.getRewardForOwner() which sends all rewards of an epoch to the attacker.
        hevm.startPrank(admin);
        voter.distribute();
        voter.vote(tokenId1, pools, weights, 0);
        voter.claimBribes(bribes, tokens, tokenId1);
        hevm.stopPrank();

        // If this attack is successful then an additional voter should not be able to claim bribes
        // Additional voter votes
        hevm.prank(beef);
        voter.vote(tokenId2, pools, weights, 0);

        hevm.warp(newEpoch());
        voter.distribute();

        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId1);
        hevm.prank(beef);
        voter.claimBribes(bribes, tokens, tokenId2);

        // This test failing indicates that the attack was successful
        assertEq(IERC20(bal).balanceOf(admin), IERC20(bal).balanceOf(beef), "earned bribes are not equal");
    }

    function testBugExtraCheckpoint() public {
        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        uint256 tokenId2 = createVeAlcx(beef, TOKEN_1, MAXTIME, false);
        address bribeAddress = voter.bribes(address(sushiGauge));

        // Add BAL bribes to sushiGauge
        createThirdPartyBribe(bribeAddress, bal, TOKEN_100K);

        address[] memory pools = new address[](1);
        pools[0] = sushiPoolAddress;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        address[] memory bribes = new address[](1);
        bribes[0] = address(bribeAddress);
        address[][] memory tokens = new address[][](1);
        tokens[0] = new address[](1);
        tokens[0][0] = bal;

        hevm.prank(admin);
        voter.vote(tokenId1, pools, weights, 0);

        hevm.prank(beef);
        voter.vote(tokenId2, pools, weights, 0);

        // Start second epoch i+1
        hevm.warp(newEpoch());
        voter.distribute();
        createThirdPartyBribe(bribeAddress, bal, TOKEN_100K);

        // When claiming a reward in contract Bribe a new checkpoint is added for the tokenId
        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId1);

        // A checkpoint in an epoch might exist even if the user did not actively vote.
        // The user can therefore claim rewards for this epoch in the future,
        // causing solvency issues as the users that voted cannot receive their share of bribes.

        // If this is the case beef wouldn't be able to claim all of the bribes from epoch i + 1
        hevm.prank(beef);
        voter.vote(tokenId2, pools, weights, 0);

        hevm.warp(newEpoch());
        voter.distribute();

        // Beef should earn all of the bribes from epoch i + 1 in addition to their bribes from epoch i
        assertEq(IBribe(bribeAddress).earned(bal, tokenId2), (TOKEN_100K / 2) + TOKEN_100K, "earned bribes incorrect");

        hevm.prank(beef);
        voter.claimBribes(bribes, tokens, tokenId2);

        // This test failing indicates that the attack was successful
        assertGt(IERC20(bal).balanceOf(beef), IERC20(bal).balanceOf(admin), "beef should capture more bribes");
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

        hevm.warp(newEpoch());
        voter.distribute();

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

        voter.distribute();

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
        hevm.warp(newEpoch());
        voter.distribute();

        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, 3 weeks, false);
        uint256 tokenId2 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        uint256[] memory tokens = new uint256[](2);
        tokens[0] = tokenId1;
        tokens[1] = tokenId2;

        address[] memory pools = new address[](1);
        pools[0] = sushiPoolAddress;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        hevm.startPrank(admin);

        // Vote and record used weights
        voter.vote(tokenId1, pools, weights, 0);
        voter.vote(tokenId2, pools, weights, 0);
        uint256 usedWeight1 = voter.usedWeights(tokenId2);
        uint256 totalWeight1 = voter.totalWeight();

        // Move to the next epoch
        hevm.warp(newEpoch());
        voter.distribute();

        // Move to when token1 expires
        hevm.warp(block.timestamp + 3 weeks);

        // Mock poking idle tokens to sync voting
        hevm.stopPrank();

        // Only admin can poke tokens
        hevm.expectRevert(abi.encodePacked("not admin"));
        voter.pokeTokens(tokens);

        hevm.prank(voter.admin());
        voter.pokeTokens(tokens);
        hevm.startPrank(admin);

        voter.distribute();

        // tokenId1 represents user who voted once and expired
        uint256 usedWeight = voter.usedWeights(tokenId1);
        assertEq(usedWeight, 0, "used weight should be 0 for expired token");

        uint256 usedWeight2 = voter.usedWeights(tokenId2);
        uint256 totalWeight2 = voter.totalWeight();

        assertGt(usedWeight1, usedWeight2, "used weight should decrease");
        assertGt(totalWeight1, totalWeight2, "total weight should decrease");

        hevm.warp(newEpoch());
        voter.distribute();

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

    function testGaugeAdminFunctions() public {
        address gaugeAdmin = sushiGauge.admin();

        hevm.prank(beef);
        hevm.expectRevert(abi.encodePacked("not admin"));
        sushiGauge.setAdmin(beef);

        hevm.prank(beef);
        hevm.expectRevert(abi.encodePacked("not admin"));
        sushiGauge.updateReceiver(beef);

        hevm.prank(gaugeAdmin);
        sushiGauge.setAdmin(beef);

        hevm.prank(gaugeAdmin);
        hevm.expectRevert(abi.encodePacked("not pending admin"));
        sushiGauge.acceptAdmin();

        hevm.prank(beef);
        sushiGauge.acceptAdmin();

        hevm.prank(beef);
        hevm.expectRevert(abi.encodePacked("cannot be zero address"));
        sushiGauge.updateReceiver(address(0));

        hevm.prank(beef);
        hevm.expectRevert(abi.encodePacked("same receiver"));
        sushiGauge.updateReceiver(sushiPoolAddress);

        hevm.prank(beef);
        sushiGauge.updateReceiver(admin);

        address newReceiver = sushiGauge.receiver();
        assertEq(newReceiver, admin, "receiver should be updated");
    }

    function testAdminFunctions() public {
        hevm.expectRevert(abi.encodePacked("not voter"));
        veALCX.updateLock(1);

        hevm.prank(address(voter));
        hevm.expectRevert(abi.encodePacked("not max locked"));
        veALCX.updateLock(1);

        hevm.expectRevert(abi.encodePacked("not emergency council"));
        voter.setEmergencyCouncil(devmsig);

        address emergencyCouncil = voter.emergencyCouncil();

        hevm.prank(emergencyCouncil);
        hevm.expectRevert(abi.encodePacked("cannot be zero address"));
        voter.setEmergencyCouncil(address(0));

        hevm.prank(emergencyCouncil);
        voter.setEmergencyCouncil(devmsig);

        hevm.expectRevert(abi.encodePacked("not admin"));
        voter.setMinter(admin);

        hevm.expectRevert(abi.encodePacked("not admin"));
        voter.setAdmin(devmsig);

        hevm.expectRevert(abi.encodePacked("not admin"));
        voter.setBoostMultiplier(1000);

        hevm.expectRevert(abi.encodePacked("not admin"));
        voter.whitelist(dai);

        hevm.expectRevert(abi.encodePacked("not admin"));
        voter.removeFromWhitelist(dai);

        hevm.expectRevert(abi.encodePacked("not admin"));
        voter.createGauge(alUsdPoolAddress, IVoter.GaugeType.Passthrough);

        hevm.prank(address(timelockExecutor));
        voter.setAdmin(devmsig);

        hevm.expectRevert(abi.encodePacked("not pending admin"));
        voter.acceptAdmin();

        hevm.startPrank(devmsig);

        voter.acceptAdmin();

        hevm.expectRevert(abi.encodePacked("Boost multiplier is out of bounds"));
        voter.setBoostMultiplier(10_000 + 1);

        voter.setBoostMultiplier(1000);

        hevm.expectRevert(abi.encodePacked("cannot be zero address"));
        voter.whitelist(address(0));

        assertEq(voter.isWhitelisted(address(0)), false, "zero address should not be whitelisted");

        hevm.expectRevert(abi.encodePacked("token not whitelisted"));
        voter.removeFromWhitelist(dai);

        voter.whitelist(dai);

        hevm.expectRevert(abi.encodePacked("token already whitelisted"));
        voter.whitelist(dai);

        assertEq(voter.isWhitelisted(dai), true, "whitelisting failed");

        voter.removeFromWhitelist(dai);

        assertEq(voter.isWhitelisted(dai), false, "remove whitelisting failed");

        hevm.stopPrank();
    }

    function testAddingRewardTokenErrors() public {
        address bribeAddress = voter.bribes(address(sushiGauge));
        hevm.prank(admin);
        hevm.expectRevert(abi.encodePacked("not being set by a gauge"));
        IBribe(bribeAddress).addRewardToken(usdt);

        hevm.prank(address(voter));
        hevm.expectRevert(abi.encodePacked("New token must be whitelisted"));
        IBribe(bribeAddress).swapOutRewardToken(0, dai, usdt);

        hevm.prank(address(timelockExecutor));
        voter.whitelist(usdt);

        hevm.prank(address(voter));
        hevm.expectRevert(abi.encodePacked("Old token mismatch"));
        IBribe(bribeAddress).swapOutRewardToken(0, usdc, usdt);

        hevm.prank(address(sushiGauge));
        IBribe(bribeAddress).addRewardToken(usdt);

        hevm.prank(address(voter));
        hevm.expectRevert(abi.encodePacked("New token already exists"));
        IBribe(bribeAddress).swapOutRewardToken(1, usdt, usdt);
    }

    function testSwapOutRewardToken() public {
        address bribeAddress = voter.bribes(address(sushiGauge));

        hevm.prank(beef);
        hevm.expectRevert(abi.encodePacked("only admin can swap reward tokens"));
        voter.swapReward(address(sushiGauge), 0, dai, usdt);

        hevm.prank(address(timelockExecutor));
        voter.whitelist(usdt);

        hevm.prank(address(sushiGauge));
        IBribe(bribeAddress).addRewardToken(usdt);

        assertEq(IBribe(bribeAddress).rewards(0), address(alcx), "reward token should be alcx");
        assertEq(IBribe(bribeAddress).rewards(1), usdt, "reward token should be usdt");

        hevm.prank(address(timelockExecutor));
        voter.whitelist(dai);

        hevm.prank(address(voter));
        IBribe(bribeAddress).swapOutRewardToken(1, usdt, dai);

        assertEq(IBribe(bribeAddress).rewards(1), dai, "reward token should have updated to be dai");
    }

    function testNotifyRewardAmountNoVotes() public {
        deal(address(alcx), address(minter), TOKEN_100K);

        uint256 minterAlcxBalance = IERC20(alcx).balanceOf(address(minter));
        assertEq(minterAlcxBalance, TOKEN_100K, "minter should have balance");

        uint256 voterAlcxBalance = IERC20(alcx).balanceOf(address(voter));
        assertEq(voterAlcxBalance, 0, "voter should have no balance");

        hevm.expectRevert(abi.encodePacked("only minter can send rewards"));
        voter.notifyRewardAmount(TOKEN_100K);

        hevm.prank(address(minter));
        // Distributing rewards without any votes should revert
        hevm.expectRevert(abi.encodePacked("no votes"));
        voter.notifyRewardAmount(TOKEN_100K);

        uint256 minterAlcxBalanceAfter = IERC20(alcx).balanceOf(address(minter));
        assertEq(minterAlcxBalanceAfter, TOKEN_100K, "minter should have the same balance");
    }

    function testNotifyRewardAmount() public {
        // Create a token and vote to create votes
        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, 3 weeks, false);

        uint256[] memory tokens = new uint256[](2);
        tokens[0] = tokenId1;

        address[] memory pools = new address[](1);
        pools[0] = sushiPoolAddress;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        hevm.prank(admin);
        voter.vote(tokenId1, pools, weights, 0);

        deal(address(alcx), address(minter), TOKEN_100K);

        uint256 minterAlcxBalance = IERC20(alcx).balanceOf(address(minter));
        assertEq(minterAlcxBalance, TOKEN_100K, "minter should have balance");

        uint256 voterAlcxBalance = IERC20(alcx).balanceOf(address(voter));
        assertEq(voterAlcxBalance, 0, "voter should have no balance");

        hevm.startPrank(address(minter));
        alcx.approve(address(voter), TOKEN_100K);
        voter.notifyRewardAmount(TOKEN_100K);
        hevm.stopPrank();

        uint256 minterAlcxBalanceAfter = IERC20(alcx).balanceOf(address(minter));
        assertEq(minterAlcxBalanceAfter, 0, "minter should have distributed its balance");

        uint256 voterAlcxBalanceAfter = IERC20(alcx).balanceOf(address(voter));
        assertEq(voterAlcxBalanceAfter, TOKEN_100K, "voter should have received balance");
    }

    function testSettingGauge() public {
        address bribeAddress = voter.bribes(address(sushiGauge));

        hevm.expectRevert(abi.encodePacked("gauge already set"));
        IBribe(bribeAddress).setGauge(devmsig);
    }

    function testVotingErrors() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        address[] memory pools = new address[](0);

        uint256[] memory weights = new uint256[](2);
        weights[0] = 5000;
        weights[1] = 5000;

        uint256[] memory weights2 = new uint256[](0);

        address[] memory pools2 = new address[](6);
        pools2[0] = sushiPoolAddress;
        pools2[1] = sushiPoolAddress;
        pools2[2] = sushiPoolAddress;
        pools2[3] = sushiPoolAddress;
        pools2[4] = sushiPoolAddress;
        pools2[5] = sushiPoolAddress;

        uint256[] memory weights3 = new uint256[](6);
        weights3[0] = 5000;
        weights3[1] = 5000;
        weights3[2] = 5000;
        weights3[3] = 5000;
        weights3[4] = 5000;
        weights3[5] = 5000;

        address[] memory gauges = new address[](1);
        gauges[0] = address(sushiGauge);

        hevm.expectRevert(abi.encodePacked("not approved or owner"));
        voter.vote(tokenId, pools, weights, 0);

        hevm.startPrank(admin);

        hevm.expectRevert(abi.encodePacked("pool vote and weights mismatch"));
        voter.vote(tokenId, pools, weights, 0);

        hevm.expectRevert(abi.encodePacked("no pools voted for"));
        voter.vote(tokenId, pools, weights2, 0);

        hevm.expectRevert(abi.encodePacked("invalid pools"));
        voter.vote(tokenId, pools2, weights3, 0);
    }
}
