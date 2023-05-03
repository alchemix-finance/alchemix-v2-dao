// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract VotingTest is BaseTest {
    function setUp() public {
        setupContracts(block.timestamp);
    }

    // Check ALCX balances increase in distributor and voter over an epoch
    function testEpochRewards() public {
        uint256 distributorBal1 = alcx.balanceOf(address(distributor));
        uint256 voterBal1 = alcx.balanceOf(address(voter));

        assertEq(distributorBal1, 0);
        assertEq(voterBal1, 0);

        hevm.warp(block.timestamp + nextEpoch);
        hevm.roll(block.number + 1);

        minter.updatePeriod();

        uint256 distributorBal2 = alcx.balanceOf(address(distributor));
        uint256 voterBal2 = alcx.balanceOf(address(voter));

        assertGt(distributorBal2, distributorBal1);
        // Voter has no balance since there have been no votes
        assertEq(voterBal2, voterBal1);

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

        assertGt(distributorBal3, distributorBal2);
        assertGt(voterBal3, voterBal2);
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

        voter.poke(tokenId, 0);

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

        uint256 claimableFlux = veALCX.claimableFlux(tokenId);
        uint256 votingWeight = veALCX.balanceOfToken(tokenId);
        uint256 maxBoostAmount = voter.maxVotingPower(tokenId);
        uint256 maxFluxAmount = voter.maxFluxBoost(tokenId);
        uint256 fluxAccessable = claimableFlux + veALCX.unclaimedFlux(tokenId);

        // Max boost amount should be the voting weight plus the boost multiplier
        assertEq(maxBoostAmount, votingWeight + maxFluxAmount);

        // Voter should revert if attempting to boost more amount of flux they have accrued and can claim
        hevm.expectRevert(abi.encodePacked("insufficient claimable FLUX balance"));
        voter.vote(tokenId, pools, weights, fluxAccessable + 1);

        // Vote should revert if attempting to boost more than the allowed amount
        hevm.expectRevert(abi.encodePacked("cannot exceed max boost"));
        voter.vote(tokenId, pools, weights, fluxAccessable);

        hevm.stopPrank();

        // Vote with the max boost amount
        hevm.prank(admin);
        voter.vote(tokenId, pools, weights, maxFluxAmount);

        hevm.prank(beef);
        voter.vote(tokenId1, pools, weights, 0);

        // Used weight should be greater when boosting with unused flux
        assertGt(voter.usedWeights(tokenId), votingWeight);

        // Token boosting with FLUX should have a higher used weight
        assertGt(voter.usedWeights(tokenId), voter.usedWeights(tokenId1));

        // Reach the end of the epoch
        hevm.warp(block.timestamp + nextEpoch);

        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId);

        hevm.prank(beef);
        voter.claimBribes(bribes, tokens, tokenId1);

        // Accout with boosted vote should capture more bribes
        assertGt(IERC20(bal).balanceOf(admin), IERC20(bal).balanceOf(beef));
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
        voter.poke(tokenId, 0);

        hevm.prank(admin);
        voter.poke(tokenId, 0);

        address[] memory poolVoteBefore = voter.getPoolVote(tokenId);

        hevm.prank(admin);
        voter.poke(tokenId, 0);

        address[] memory poolVoteAfter = voter.getPoolVote(tokenId);

        // Calling poke multiple times should not inflate the voting balance
        assertEq(poolVoteBefore[0], poolVoteAfter[0], "voting balance inflated");

        // Last voted should be updated
        assertEq(voter.lastVoted(tokenId), block.timestamp, "last voted not updated");

        // Pool vote should remain the same after poke
        poolVote = voter.getPoolVote(tokenId);
        assertEq(poolVote[0], alETHPool);

        // Next epoch
        hevm.warp(block.timestamp + nextEpoch);

        uint256 claimableFlux = veALCX.claimableFlux(tokenId);

        // Poke should revert if attempting to boost more than the allowed amount
        hevm.prank(admin);
        hevm.expectRevert(abi.encodePacked("cannot exceed max boost"));
        voter.poke(tokenId, claimableFlux);
    }

    // Test voting on gauges to earn third party bribes
    function testBribes() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        address bribeAddress = voter.bribes(address(sushiGauge));
        uint256 rewardsLength = IBribe(bribeAddress).rewardsListLength();

        // Add BAL bribes to sushiGauge
        createThirdPartyBribe(bribeAddress, bal, TOKEN_100K);

        // Tokens should have to be added to the whitelist before being able to bribe
        hevm.expectRevert(abi.encodePacked("bribe tokens must be whitelisted"));
        IBribe(bribeAddress).notifyRewardAmount(usdc, TOKEN_100K);

        uint256 bribeBalance = IERC20(bal).balanceOf(bribeAddress);
        // Bribe contract should increase in bribe token balance
        assertEq(TOKEN_100K, bribeBalance);

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
        tokens[0] = new address[](1);
        tokens[0][0] = bal;

        hevm.prank(admin);
        voter.vote(tokenId, pools, weights, 0);

        // Reach the end of the epoch
        hevm.warp(block.timestamp + nextEpoch);

        uint256 earnedBribes = IBribe(bribeAddress).earned(bal, tokenId);

        // Prior balance and supply should be zero since this is the first epoch for this voter
        assertEq(IBribe(bribeAddress).getPriorBalanceIndex(tokenId, block.timestamp), 0);
        assertEq(IBribe(bribeAddress).getPriorSupplyIndex(block.timestamp), 0);

        // Earned bribes should be all bribes
        assertEq(earnedBribes, TOKEN_100K);

        hevm.prank(admin);
        voter.claimBribes(bribes, tokens, tokenId);

        // The voter should capture all earned bribes
        assertEq(IERC20(bal).balanceOf(admin), earnedBribes);

        // Bribe address balance should be depleted by earned amount
        assertEq(bribeBalance - earnedBribes, IERC20(bal).balanceOf(bribeAddress));
    }

    // Votes cannot be boosted with insufficient claimable flux balance
    function testCannotBoostVote() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        hevm.startPrank(admin);

        hevm.warp(block.timestamp + nextEpoch);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        uint256 claimableFlux = veALCX.claimableFlux(tokenId);

        // Vote with insufficient claimable flux balance
        hevm.expectRevert(abi.encodePacked("insufficient claimable FLUX balance"));
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
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, 3 weeks, false);

        hevm.startPrank(admin);

        hevm.warp(block.timestamp + 3 weeks);

        uint256 balance = veALCX.balanceOfToken(tokenId);

        // Voting power decays to 0
        hevm.expectRevert(abi.encodePacked("Cannot add to expired lock. Withdraw"));
        veALCX.increaseAmount(tokenId, TOKEN_1);
        assertEq(balance, 0);

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
