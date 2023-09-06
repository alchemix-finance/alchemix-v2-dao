// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract VotingEscrowTest is BaseTest {
    uint256 internal constant ONE_WEEK = 1 weeks;
    uint256 internal constant THREE_WEEKS = 3 weeks;
    uint256 internal constant FIVE_WEEKS = 5 weeks;
    uint256 maxDuration = ((block.timestamp + MAXTIME) / ONE_WEEK) * ONE_WEEK;

    function setUp() public {
        setupContracts(block.timestamp);
    }

    // Create veALCX
    function testCreateLock() public {
        hevm.startPrank(admin);

        assertEq(veALCX.balanceOf(admin), 0);

        uint256 tokenId = veALCX.createLock(TOKEN_1, THREE_WEEKS, false);

        assertEq(veALCX.isApprovedForAll(admin, address(0)), false);
        assertEq(veALCX.getApproved(1), address(0));
        assertEq(veALCX.userPointHistoryTimestamp(1, 1), block.timestamp);

        assertEq(veALCX.ownerOf(tokenId), admin);
        assertEq(veALCX.balanceOf(admin), tokenId);

        hevm.stopPrank();
    }

    function testCreateLockFailed() public {
        hevm.startPrank(admin);

        assertEq(veALCX.balanceOf(admin), 0);

        hevm.expectRevert(abi.encodePacked("cannot mint to zero address"));
        veALCX.createLockFor(TOKEN_1, THREE_WEEKS, false, address(0));

        hevm.stopPrank();
    }

    // Test depositing, withdrawing from a rewardPool (Aura pool)
    function testRewardPool() public {
        // Reward pool should be set
        assertEq(rewardPool, veALCX.rewardPool());

        deal(bpt, address(veALCX), TOKEN_1);

        // Initial amount of bal and aura rewards earned
        uint256 rewardBalanceBefore1 = IERC20(bal).balanceOf(admin);
        uint256 rewardBalanceBefore2 = IERC20(aura).balanceOf(admin);
        assertEq(rewardBalanceBefore1, 0, "rewardBalanceBefore1 should be 0");
        assertEq(rewardBalanceBefore2, 0, "rewardBalanceBefore2 should be 0");

        // Initial BPT balance of veALCX
        uint256 amount = IERC20(bpt).balanceOf(address(veALCX));
        assertEq(amount, TOKEN_1);

        // Deposit BPT balance into rewardPool
        hevm.prank(admin);
        veALCX.depositIntoRewardPool(amount);

        uint256 amountAfterDeposit = IERC20(bpt).balanceOf(address(veALCX));
        assertEq(amountAfterDeposit, 0, "full balance should be deposited");

        uint256 rewardPoolBalance = IRewardPool4626(rewardPool).balanceOf(address(veALCX));
        assertEq(rewardPoolBalance, amount, "rewardPool balance should equal amount deposited");

        // Fast forward to accumulate rewards
        hevm.warp(block.timestamp + 2 weeks);

        hevm.prank(admin);
        veALCX.claimRewardPoolRewards();
        uint256 rewardBalanceAfter1 = IERC20(bal).balanceOf(address(admin));
        uint256 rewardBalanceAfter2 = IERC20(aura).balanceOf(address(admin));

        // After claiming rewards admin bal balance should increase
        assertGt(rewardBalanceAfter1, rewardBalanceBefore1, "should accumulate bal rewards");
        assertGt(rewardBalanceAfter2, rewardBalanceBefore2, "should accumulate aura rewards");

        hevm.prank(admin);
        veALCX.withdrawFromRewardPool(amount);

        // veALCX BPT balance should equal original amount after withdrawing from rewardPool
        uint256 amountAfterWithdraw = IERC20(bpt).balanceOf(address(veALCX));
        assertEq(amountAfterWithdraw, amount, "should equal original amount");

        // Only veALCX admin can update rewardPool
        hevm.expectRevert(abi.encodePacked("not admin"));
        veALCX.updateRewardPool(sushiPoolAddress);

        hevm.prank(admin);
        veALCX.updateRewardPool(sushiPoolAddress);

        // Reward pool should update
        assertEq(sushiPoolAddress, veALCX.rewardPool(), "rewardPool not updated");
    }

    function testUpdateLockDuration() public {
        hevm.startPrank(admin);

        uint256 tokenId = veALCX.createLock(TOKEN_1, 5 weeks, true);

        uint256 lockEnd = veALCX.lockEnd(tokenId);

        // Lock end should be max time when max lock is enabled
        assertEq(lockEnd, maxDuration);

        veALCX.updateUnlockTime(tokenId, 1 days, true);

        lockEnd = veALCX.lockEnd(tokenId);

        // Lock duration should be unchanged
        assertEq(lockEnd, maxDuration);

        veALCX.updateUnlockTime(tokenId, 1 days, false);

        lockEnd = veALCX.lockEnd(tokenId);

        // Lock duration should be unchanged
        assertEq(lockEnd, maxDuration);

        // Now that max lock is disabled lock duration can be set again
        hevm.expectRevert(abi.encodePacked("Voting lock can be 1 year max"));

        veALCX.updateUnlockTime(tokenId, MAXTIME + ONE_WEEK, false);

        hevm.warp(block.timestamp + 260 days);

        lockEnd = veALCX.lockEnd(tokenId);

        // Able to increase lock end now that previous lock end is closer
        veALCX.updateUnlockTime(tokenId, 200 days, false);

        // Updated lock end should be greater than previous lockEnd
        assertGt(veALCX.lockEnd(tokenId), lockEnd);

        hevm.stopPrank();
    }

    // Locking outside the allowed zones should revert
    function testInvalidLock() public {
        hevm.startPrank(admin);

        hevm.expectRevert(abi.encodePacked("Voting lock can be 1 year max"));

        veALCX.createLock(TOKEN_1, MAXTIME + ONE_WEEK, false);

        hevm.stopPrank();
    }

    // Votes should increase as veALCX is created
    function testVotes() public {
        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1 / 2, THREE_WEEKS, false);
        uint256 tokenId2 = createVeAlcx(admin, TOKEN_1 / 2, THREE_WEEKS * 2, false);

        uint256 maxVotingPower = getMaxVotingPower(TOKEN_1 / 2, veALCX.lockEnd(tokenId1)) +
            getMaxVotingPower(TOKEN_1 / 2, veALCX.lockEnd(tokenId2));

        uint256 totalVotes = veALCX.totalSupply();

        uint256 totalVotesAt = veALCX.totalSupplyAtT(block.timestamp);

        assertEq(totalVotes, totalVotesAt);

        uint256 votingPower = veALCX.balanceOfToken(tokenId1) + veALCX.balanceOfToken(tokenId2);

        assertEq(votingPower, totalVotes, "votes doesn't match total");

        assertEq(votingPower, maxVotingPower, "votes doesn't match total");
    }

    // Test tracking of checkpoints and calculating votes at points in time
    function testPastVotesIndex() public {
        uint256 voteTimestamp0 = block.timestamp;

        uint256 period = minter.activePeriod();
        hevm.warp(period + nextEpoch);

        // Create three tokens within the same block
        // Creates a new checkpoint at index 0
        createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        // get original voting power of admin
        uint256 originalVotingPower = veALCX.getVotes(admin);

        // Only one checkpoint should be created since tokens are created in the same block
        uint256 numCheckpoints = veALCX.numCheckpoints(admin);
        assertEq(numCheckpoints, 1, "numCheckpoints should be 1");

        uint256 voteTimestamp1 = block.timestamp;

        hevm.warp(block.timestamp + nextEpoch * 2);
        minter.updatePeriod();

        // Creates a new checkpoint at index 1
        createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        uint256 voteTimestamp2 = block.timestamp;

        hevm.warp(block.timestamp + nextEpoch * 5);
        minter.updatePeriod();

        // Creates a new checkpoint at index 2
        createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        uint256 voteTimestamp3 = block.timestamp;

        uint256 pastVotes0 = veALCX.getPastVotes(admin, voteTimestamp0 - nextEpoch);
        assertEq(pastVotes0, 0, "no voting power when timestamp was before first checkpoint");

        uint256 pastVotes1 = veALCX.getPastVotes(admin, voteTimestamp1);
        assertEq(pastVotes1, originalVotingPower, "voting power should be original amount");

        uint256 pastVotesIndex2 = veALCX.getPastVotesIndex(admin, voteTimestamp2);
        assertEq(pastVotesIndex2, 1, "index should be closest to timestamp");

        uint256 pastVotesIndex3 = veALCX.getPastVotesIndex(admin, voteTimestamp3 + nextEpoch * 2);
        assertEq(pastVotesIndex3, 2, "index should be closest to timestamp");
    }

    // Calculating voting power at points in time should be correct
    function testBalanceOfTokenCalcs() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, THREE_WEEKS, false);

        uint256 originalTimestamp = block.timestamp;

        uint256 originalVotingPower = veALCX.balanceOfToken(tokenId);

        hevm.warp(block.timestamp + nextEpoch);
        minter.updatePeriod();

        uint256 decayedTimestamp = block.timestamp;

        uint256 decayedVotingPower = veALCX.balanceOfToken(tokenId);
        assertGt(originalVotingPower, decayedVotingPower, "voting power should be less than original");

        // Getting the voting power at a point in time should return the expected result
        uint256 getOriginalVotingPower = veALCX.balanceOfTokenAt(tokenId, originalTimestamp);
        assertEq(getOriginalVotingPower, originalVotingPower, "voting power should be equal");

        hevm.warp(block.timestamp + nextEpoch);
        minter.updatePeriod();

        // Getting the voting power at a point in time should return the expected result
        uint256 getDecayedVotingPower = veALCX.balanceOfTokenAt(tokenId, decayedTimestamp);
        assertEq(getDecayedVotingPower, decayedVotingPower, "voting powers should be equal");

        // Token is expired starting in this epoch
        hevm.warp(block.timestamp + nextEpoch);

        uint256 expiredVotingPower = veALCX.balanceOfToken(tokenId);
        assertEq(expiredVotingPower, 0, "voting power should be 0 after lock expires");

        // Voting power before token was created should be 0
        uint256 getPastVotingPower = veALCX.balanceOfTokenAt(tokenId, originalTimestamp - nextEpoch);
        assertEq(getPastVotingPower, 0, "voting power should be 0");
    }

    // A token should be able to disable max lock
    function testDisableMaxLock() public {
        hevm.startPrank(admin);

        uint256 tokenId = veALCX.createLock(TOKEN_1, 0, true);

        hevm.warp(block.timestamp + MAXTIME + nextEpoch);

        uint256 lockEnd1 = veALCX.lockEnd(tokenId);
        // Lock end has technically passed but the token is max locked
        assertGt(block.timestamp, lockEnd1, "lock should have ended");

        // Should be able to disable max lock after lock end has passed
        veALCX.updateUnlockTime(tokenId, 0, false);

        uint256 lockEnd2 = veALCX.lockEnd(tokenId);
        assertGt(lockEnd2, block.timestamp, "lock end should be updated");

        hevm.warp(block.timestamp + lockEnd2);

        // Should be able to cooldown and withdraw after new lock end has passed
        veALCX.startCooldown(tokenId);
        hevm.warp(block.timestamp + nextEpoch);
        veALCX.withdraw(tokenId);

        hevm.stopPrank();
    }

    // Withdraw enabled after lock expires
    function testWithdraw() public {
        hevm.startPrank(admin);

        uint256 tokenId = veALCX.createLock(TOKEN_1, THREE_WEEKS, false);

        uint256 bptBalanceBefore = IERC20(bpt).balanceOf(admin);

        uint256 fluxBalanceBefore = IERC20(flux).balanceOf(admin);
        uint256 alcxBalanceBefore = IERC20(alcx).balanceOf(admin);

        hevm.expectRevert(abi.encodePacked("Cooldown period has not started"));
        veALCX.withdraw(tokenId);

        voter.reset(tokenId);

        hevm.warp(block.timestamp + THREE_WEEKS);

        minter.updatePeriod();

        uint256 unclaimedAlcx = distributor.claimable(tokenId);
        uint256 unclaimedFlux = veALCX.unclaimedFlux(tokenId);

        // Start cooldown once lock is expired
        veALCX.startCooldown(tokenId);

        hevm.expectRevert(abi.encodePacked("Cooldown period in progress"));
        veALCX.withdraw(tokenId);

        hevm.warp(block.timestamp + nextEpoch);

        veALCX.withdraw(tokenId);

        uint256 bptBalanceAfter = IERC20(bpt).balanceOf(admin);
        uint256 fluxBalanceAfter = IERC20(flux).balanceOf(admin);
        uint256 alcxBalanceAfter = IERC20(alcx).balanceOf(admin);

        // Bpt balance after should increase by the withdraw amount
        assertEq(bptBalanceAfter - bptBalanceBefore, TOKEN_1);

        // ALCX and flux balance should increase
        assertEq(alcxBalanceAfter, alcxBalanceBefore + unclaimedAlcx, "didn't claim alcx");
        assertEq(fluxBalanceAfter, fluxBalanceBefore + unclaimedFlux, "didn't claim flux");

        // Check that the token is burnt
        assertEq(veALCX.balanceOfToken(tokenId), 0);
        assertEq(veALCX.ownerOf(tokenId), address(0));

        hevm.stopPrank();
    }

    function testFluxAccrual() public {
        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        uint256 tokenId2 = createVeAlcx(beef, TOKEN_1, 3 weeks, false);
        uint256 tokenId3 = createVeAlcx(holder, TOKEN_1, 3 weeks, false);

        hevm.prank(admin);
        voter.reset(tokenId1);

        hevm.prank(beef);
        voter.reset(tokenId2);

        hevm.prank(holder);
        voter.reset(tokenId3);

        uint256 unclaimedFlux1 = veALCX.unclaimedFlux(tokenId1);
        uint256 unclaimedFlux2 = veALCX.unclaimedFlux(tokenId2);

        assertGt(unclaimedFlux1, unclaimedFlux2, "unclaimed flux should be greater for longer lock");

        // Start new epoch
        hevm.warp(block.timestamp + nextEpoch);
        minter.updatePeriod();

        hevm.prank(holder);
        voter.reset(tokenId3);

        unclaimedFlux2 = veALCX.unclaimedFlux(tokenId2);
        uint256 unclaimedFlux3 = veALCX.unclaimedFlux(tokenId3);

        assertGt(unclaimedFlux3, unclaimedFlux2, "unclaimed flux should be greater for active voter");
    }

    // Voting should not impact amount of ALCX rewards earned
    function testRewardsClaiming() public {
        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        uint256 tokenId2 = createVeAlcx(beef, TOKEN_1, MAXTIME, false);

        hevm.prank(admin);
        voter.reset(tokenId1);

        // Start new epoch
        hevm.warp(block.timestamp + nextEpoch);
        minter.updatePeriod();

        hevm.prank(admin);
        voter.reset(tokenId1);

        // Start new epoch
        hevm.warp(block.timestamp + nextEpoch);
        minter.updatePeriod();

        uint256 claimable1 = distributor.claimable(tokenId1);
        uint256 claimable2 = distributor.claimable(tokenId2);

        assertEq(claimable1, claimable2, "claimable amounts should be equal");
    }

    // Calling tokenURI should not work for non-existent token ids
    function testTokenURICalls() public {
        hevm.startPrank(admin);

        uint256 tokenId = veALCX.createLock(TOKEN_1, THREE_WEEKS, false);

        hevm.expectRevert(abi.encodePacked("Query for nonexistent token"));
        veALCX.tokenURI(999);

        hevm.warp(block.timestamp + THREE_WEEKS);
        hevm.roll(block.number + 1);

        // Check that new token doesn't revert
        veALCX.tokenURI(tokenId);

        veALCX.startCooldown(tokenId);

        hevm.warp(block.timestamp + THREE_WEEKS);

        // Withdraw, which destroys the token
        veALCX.withdraw(tokenId);

        // tokenURI should not work for this anymore as the token is burnt
        hevm.expectRevert(abi.encodePacked("Query for nonexistent token"));
        veALCX.tokenURI(tokenId);

        hevm.stopPrank();
    }

    // Check support of supported interfaces
    function testSupportedInterfaces() public {
        bytes4 ERC165_INTERFACE_ID = 0x01ffc9a7;
        bytes4 ERC721_INTERFACE_ID = 0x80ac58cd;
        bytes4 ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;

        assertTrue(veALCX.supportsInterface(ERC165_INTERFACE_ID));
        assertTrue(veALCX.supportsInterface(ERC721_INTERFACE_ID));
        assertTrue(veALCX.supportsInterface(ERC721_METADATA_INTERFACE_ID));
    }

    // Check support of unsupported interfaces
    function testUnsupportedInterfaces() public {
        bytes4 ERC721_FAKE = 0x780e9d61;
        assertFalse(veALCX.supportsInterface(ERC721_FAKE));
    }

    // Check approving another address of veALCX
    function testApprovedOrOwner() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        hevm.startPrank(admin);

        hevm.expectRevert(abi.encodePacked("Approved is already owner"));
        veALCX.approve(admin, tokenId);

        veALCX.approve(beef, tokenId);

        assertEq(veALCX.isApprovedOrOwner(beef, tokenId), true);

        hevm.stopPrank();
    }

    // Check transfer of veALCX
    function testTransferToken() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        hevm.startPrank(admin);

        assertEq(veALCX.ownerOf(tokenId), admin);

        hevm.expectRevert(abi.encodePacked("ERC721: transfer to non ERC721Receiver implementer"));
        veALCX.safeTransferFrom(admin, alETHPool, tokenId);

        veALCX.safeTransferFrom(admin, beef, tokenId);

        assertEq(veALCX.ownerOf(tokenId), beef);

        hevm.stopPrank();
    }

    // Check merging of two veALCX
    function testMergeTokens() public {
        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        uint256 tokenId2 = createVeAlcx(admin, TOKEN_100K, FIVE_WEEKS, false);

        hevm.startPrank(admin);

        uint256 lockEnd1 = veALCX.lockEnd(tokenId1);

        assertEq(lockEnd1, ((block.timestamp + MAXTIME) / 1 weeks) * 1 weeks);
        assertEq(veALCX.lockedAmount(tokenId1), TOKEN_1);

        // Vote to trigger flux accrual
        hevm.warp(block.timestamp + nextEpoch);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;
        voter.vote(tokenId1, pools, weights, 0);
        voter.vote(tokenId2, pools, weights, 0);

        minter.updatePeriod();

        hevm.warp(block.timestamp + nextEpoch);

        // Reset to allow merging of tokens
        voter.reset(tokenId1);
        voter.reset(tokenId2);

        uint256 unclaimedFluxBefore1 = veALCX.unclaimedFlux(tokenId1);
        uint256 unclaimedFluxBefore2 = veALCX.unclaimedFlux(tokenId2);

        hevm.expectRevert(abi.encodePacked("must be different tokens"));
        veALCX.merge(tokenId1, tokenId1);

        veALCX.merge(tokenId1, tokenId2);

        uint256 unclaimedFluxAfter1 = veALCX.unclaimedFlux(tokenId1);
        uint256 unclaimedFluxAfter2 = veALCX.unclaimedFlux(tokenId2);

        // After merge unclaimed flux should consolidate into one token
        assertEq(unclaimedFluxAfter2, unclaimedFluxBefore1 + unclaimedFluxBefore2, "unclaimed flux not consolidated");
        assertEq(unclaimedFluxAfter1, 0, "incorrect unclaimed flux");

        // Merged token should take longer of the two lock end dates
        assertEq(veALCX.lockEnd(tokenId2), lockEnd1);

        // Merged token should have sum of both token locked amounts
        assertEq(veALCX.lockedAmount(tokenId2), TOKEN_1 + TOKEN_100K);

        // Token with smaller locked amount should be burned
        assertEq(veALCX.ownerOf(tokenId1), address(0));

        hevm.stopPrank();
    }

    // A user should not be able to withdraw BPT early
    function testManipulateEarlyUnlock() public {
        uint256 tokenId1 = createVeAlcx(admin, TOKEN_100K, MAXTIME, false);
        uint256 tokenId2 = createVeAlcx(admin, TOKEN_1, THREE_WEEKS, false);
        uint256 tokenId3 = createVeAlcx(admin, TOKEN_1, FIVE_WEEKS, false);
        uint256 tokenId4 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        // Mint the necessary amount of flux to ragequit
        uint256 ragequitAmount = veALCX.amountToRagequit(tokenId4);
        hevm.prank(address(veALCX));
        flux.mint(admin, ragequitAmount);

        // Fast forward to lock end of tokenId2
        hevm.warp(block.timestamp + THREE_WEEKS);

        hevm.startPrank(admin);

        // Should not be able to withdraw BPT
        hevm.expectRevert(abi.encodePacked("Cooldown period has not started"));
        veALCX.withdraw(tokenId1);

        // Should not be able to withdraw BPT
        hevm.expectRevert(abi.encodePacked("Cooldown period has not started"));
        veALCX.withdraw(tokenId2);

        // Merge should not be possible with expired token
        hevm.expectRevert(abi.encodePacked("Cannot merge when lock expired"));
        veALCX.merge(tokenId1, tokenId2);

        flux.approve(address(veALCX), ragequitAmount);
        veALCX.startCooldown(tokenId4);
        // Dispose of flux minted for testing
        flux.transfer(beef, flux.balanceOf(admin));

        // Merge should not be possible when token lock has expired
        hevm.expectRevert(abi.encodePacked("Cannot merge when lock expired"));
        veALCX.merge(tokenId1, tokenId2);

        // Merge should not be possible when token cooldown has started
        hevm.expectRevert(abi.encodePacked("Cannot merge when cooldown period in progress"));
        veALCX.merge(tokenId1, tokenId4);

        uint256 oldLockEnd = veALCX.lockEnd(tokenId1);

        // Merge with valid token should be possible
        veALCX.merge(tokenId1, tokenId3);

        // Early unlock should not be possible since balance has increased
        hevm.expectRevert(abi.encodePacked("insufficient FLUX balance"));
        veALCX.startCooldown(tokenId3);

        // Withdraw from tokenId3 should not be possible
        hevm.expectRevert(abi.encodePacked("Cooldown period has not started"));
        veALCX.withdraw(tokenId3);

        // Lock end of token should be updated
        uint256 newLockEnd = veALCX.lockEnd(tokenId3);
        assertEq(newLockEnd, oldLockEnd);

        hevm.stopPrank();
    }

    function testRagequit() public {
        hevm.startPrank(admin);

        uint256 tokenId = veALCX.createLock(TOKEN_1, THREE_WEEKS, false);

        // Show that veALCX is not expired
        hevm.expectRevert(abi.encodePacked("Cooldown period has not started"));
        veALCX.withdraw(tokenId);

        // admin doesn't have enough flux
        hevm.expectRevert(abi.encodePacked("insufficient FLUX balance"));
        veALCX.startCooldown(tokenId);

        hevm.stopPrank();

        uint256 ragequitAmount = veALCX.amountToRagequit(tokenId);

        // Mint the necessary amount of flux to ragequit
        hevm.prank(address(veALCX));
        flux.mint(admin, ragequitAmount);

        hevm.startPrank(admin);

        flux.approve(address(veALCX), ragequitAmount);

        veALCX.startCooldown(tokenId);

        hevm.roll(block.number + 1);

        hevm.expectRevert(abi.encodePacked("Cooldown period in progress"));
        veALCX.withdraw(tokenId);

        assertEq(veALCX.cooldownEnd(tokenId), block.timestamp + ONE_WEEK);

        hevm.warp(block.timestamp + ONE_WEEK + 1 days);

        veALCX.withdraw(tokenId);

        hevm.roll(block.number + 1);

        // Check that the token is burnt
        assertEq(veALCX.balanceOfToken(tokenId), 0);
        assertEq(veALCX.ownerOf(tokenId), address(0));

        hevm.stopPrank();
    }

    // Test that the total supply is updated correctly when a token ragequits
    function testRagequitSupplyImpact() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, THREE_WEEKS, false);

        uint256 ragequitAmount = veALCX.amountToRagequit(tokenId);

        // Ragequit and withdraw token
        hevm.prank(address(veALCX));
        flux.mint(admin, ragequitAmount);
        hevm.startPrank(admin);
        flux.approve(address(veALCX), ragequitAmount);
        veALCX.startCooldown(tokenId);
        hevm.warp(block.timestamp + ONE_WEEK + 1 days);

        uint256 totalVotesBefore = veALCX.totalSupply();
        uint256 balanceOfToken = veALCX.balanceOfToken(tokenId);

        veALCX.withdraw(tokenId);

        // Check that the token is burnt and has no voting power
        assertEq(veALCX.balanceOfToken(tokenId), 0);
        assertEq(veALCX.ownerOf(tokenId), address(0));

        uint256 totalVotesAfter = veALCX.totalSupply();
        assertEq(totalVotesAfter, totalVotesBefore - balanceOfToken, "total should decrease by balance of token");

        hevm.stopPrank();
    }

    // It should take MAXTIME * fluxMultiplier to accrue enough flux to ragequit
    function testFluxAccrualOverTime() public {
        hevm.startPrank(admin);

        uint256 tokenId = veALCX.createLock(TOKEN_1, MAXTIME, true);

        uint256 claimedBalance = flux.balanceOf(admin);
        uint256 unclaimedBalance = veALCX.unclaimedFlux(tokenId);
        uint256 ragequitAmount = veALCX.amountToRagequit(tokenId);

        assertEq(claimedBalance, 0);
        assertEq(unclaimedBalance, 0);

        voter.reset(tokenId);

        unclaimedBalance = veALCX.unclaimedFlux(tokenId);

        // Flux accrued over one epoch should align with the fluxMultiplier and epoch length
        uint256 fluxCalc = unclaimedBalance * veALCX.fluxMultiplier() * veALCX.EPOCH();

        assertApproxEq(fluxCalc, ragequitAmount, 1e18);
    }

    function testGetPastTotalSupply() public {
        createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        minter.updatePeriod();
        hevm.warp(block.timestamp + 1 weeks + 1);
        hevm.roll(block.number + 1 weeks / 12);

        assertGt(
            veALCX.getPastTotalSupply(block.timestamp - 2 days),
            veALCX.getPastTotalSupply(block.timestamp - 1 days),
            "before second update"
        );

        minter.updatePeriod();

        assertGt(
            veALCX.getPastTotalSupply(block.timestamp - 2 days),
            veALCX.getPastTotalSupply(block.timestamp - 1 days),
            "after second update"
        );

        hevm.warp(block.timestamp + 1 weeks + 1);
        hevm.roll(block.number + 1 weeks / 12);

        assertGt(
            veALCX.getPastTotalSupply(block.timestamp - 2 days),
            veALCX.getPastTotalSupply(block.timestamp - 1 days),
            "before third update"
        );

        minter.updatePeriod();

        assertGt(
            veALCX.getPastTotalSupply(block.timestamp - 2 days),
            veALCX.getPastTotalSupply(block.timestamp - 1 days),
            "after third update"
        );

        hevm.warp(block.timestamp + 1 weeks + 1);
        hevm.roll(block.number + 1 weeks / 12);

        assertGt(
            veALCX.getPastTotalSupply(block.timestamp - 2 days),
            veALCX.getPastTotalSupply(block.timestamp - 1 days),
            "after final warp"
        );
    }

    function testTotalSupplyAtT() public {
        createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        minter.updatePeriod();
        hevm.warp(block.timestamp + 1 weeks + 1);
        hevm.roll(block.number + 1 weeks / 12);

        assertGt(
            veALCX.totalSupplyAtT(block.timestamp - 2 days),
            veALCX.totalSupplyAtT(block.timestamp - 1 days),
            "before second update"
        );

        minter.updatePeriod();

        assertGt(
            veALCX.totalSupplyAtT(block.timestamp - 2 days),
            veALCX.totalSupplyAtT(block.timestamp - 1 days),
            "after second update"
        );

        hevm.warp(block.timestamp + 1 weeks + 1);
        hevm.roll(block.number + 1 weeks / 12);

        assertGt(
            veALCX.totalSupplyAtT(block.timestamp - 2 days),
            veALCX.totalSupplyAtT(block.timestamp - 1 days),
            "before third update"
        );

        minter.updatePeriod();

        // Check that the RewardsDistributor and veALCX are in sync
        uint256 timeCursor = distributor.timeCursor();
        uint256 veSupply = distributor.veSupply(timeCursor - 1 weeks);
        uint256 supplyAt = veALCX.totalSupplyAtT(timeCursor - 1 weeks);

        assertEq(veSupply, supplyAt, "veSupply should equal supplyAt");

        assertGt(
            veALCX.totalSupplyAtT(block.timestamp - 2 days),
            veALCX.totalSupplyAtT(block.timestamp - 1 days),
            "after third update"
        );

        hevm.warp(block.timestamp + 1 weeks + 1);
        hevm.roll(block.number + 1 weeks / 12);

        assertGt(
            veALCX.totalSupplyAtT(block.timestamp - 2 days),
            veALCX.totalSupplyAtT(block.timestamp - 1 days),
            "after final warp"
        );
    }

    function testBalanceOfTokenAt() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        minter.updatePeriod();
        hevm.warp(block.timestamp + 1 weeks + 1);
        hevm.roll(block.number + 1 weeks / 12);

        assertGt(
            veALCX.balanceOfTokenAt(tokenId, block.timestamp - 2 days),
            veALCX.balanceOfTokenAt(tokenId, block.timestamp - 1 days),
            "before second update"
        );

        minter.updatePeriod();
        deal(bpt, address(this), TOKEN_1);
        IERC20(bpt).approve(address(veALCX), TOKEN_1);
        veALCX.depositFor(tokenId, TOKEN_1);

        assertGt(
            veALCX.balanceOfTokenAt(tokenId, block.timestamp - 2 days),
            veALCX.balanceOfTokenAt(tokenId, block.timestamp - 1 days),
            "after second update"
        );

        hevm.warp(block.timestamp + 1 weeks + 1);
        hevm.roll(block.number + 1 weeks / 12);

        assertGt(
            veALCX.balanceOfTokenAt(tokenId, block.timestamp - 2 days),
            veALCX.balanceOfTokenAt(tokenId, block.timestamp - 1 days),
            "before third update"
        );

        minter.updatePeriod();
        deal(bpt, address(this), TOKEN_1);
        IERC20(bpt).approve(address(veALCX), TOKEN_1);
        veALCX.depositFor(tokenId, TOKEN_1);

        assertGt(
            veALCX.balanceOfTokenAt(tokenId, block.timestamp - 2 days),
            veALCX.balanceOfTokenAt(tokenId, block.timestamp - 1 days),
            "after third update"
        );

        hevm.warp(block.timestamp + 1 weeks + 1);
        hevm.roll(block.number + 1 weeks / 12);

        assertGt(
            veALCX.balanceOfTokenAt(tokenId, block.timestamp - 2 days),
            veALCX.balanceOfTokenAt(tokenId, block.timestamp - 1 days),
            "after final warp"
        );
    }

    function testManipulatePastBalanceWithDeposit(uint256 time) public {
        hevm.assume(time < block.timestamp + 3 days);

        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        minter.updatePeriod();
        hevm.warp(block.timestamp + 3 days);
        hevm.roll(block.number + 3 days / 12);

        uint256 t2Dp1 = block.timestamp - (2 days + 1);
        uint256 t2Dm1 = block.timestamp - (2 days - 1);

        uint256 bal2DaysPlus1 = veALCX.balanceOfTokenAt(tokenId, t2Dp1);
        uint256 bal2DaysMinus1 = veALCX.balanceOfTokenAt(tokenId, t2Dm1);

        assertGt(bal2DaysPlus1, bal2DaysMinus1, "first check");

        deal(bpt, address(this), TOKEN_1);
        IERC20(bpt).approve(address(veALCX), TOKEN_1);
        veALCX.depositFor(tokenId, TOKEN_1);

        assertEq(veALCX.balanceOfTokenAt(tokenId, t2Dp1), bal2DaysPlus1, "after deposit, 2 days + 1");
        assertEq(veALCX.balanceOfTokenAt(tokenId, t2Dm1), bal2DaysMinus1, "after deposit, 2 days - 1");

        // Check that binary search always returns an epoch with timestamp less than time
        assertGt(
            veALCX.balanceOfToken(tokenId),
            veALCX.balanceOfTokenAt(tokenId, time),
            "point in time should always be less than current time"
        );
    }

    function testManipulatePastSupplyWithDeposit() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        minter.updatePeriod();
        hevm.warp(block.timestamp + 1 weeks + 1);
        hevm.roll(block.number + 1 weeks / 12);

        uint256 t2Dp1 = block.timestamp - (2 days + 1);
        uint256 t2Dm1 = block.timestamp - (2 days - 1);

        uint256 bal2DaysPlus1 = veALCX.totalSupplyAtT(t2Dp1);
        uint256 bal2DaysMinus1 = veALCX.totalSupplyAtT(t2Dm1);

        assertGt(bal2DaysPlus1, bal2DaysMinus1, "first check");

        deal(bpt, address(this), TOKEN_1);
        IERC20(bpt).approve(address(veALCX), TOKEN_1);
        veALCX.depositFor(tokenId, TOKEN_1);
        minter.updatePeriod();

        assertEq(veALCX.totalSupplyAtT(t2Dp1), bal2DaysPlus1, "after deposit, 2 days + 1");
        assertEq(veALCX.totalSupplyAtT(t2Dm1), bal2DaysMinus1, "after deposit, 2 days - 1");
    }

    function testTotalSupplyWithMaxlock() public {
        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, MAXTIME, true);

        uint256 numCheckpoints = veALCX.numCheckpoints(admin);
        assertEq(numCheckpoints, 1, "numCheckpoints should be 1");

        hevm.warp(block.timestamp + nextEpoch * 45);
        minter.updatePeriod();

        uint256 totalPower = veALCX.totalSupply();
        uint256 tokenPower = veALCX.balanceOfToken(tokenId1);

        assertEq(tokenPower, totalPower, "total supply should equal voting power");
    }

    function testMovingDelegates() public {
        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
        uint256 tokenId2 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        uint256 balanceOfTokens = veALCX.balanceOfToken(tokenId1) + veALCX.balanceOfToken(tokenId2);
        uint256 originalVotingPowerAdmin = veALCX.getVotes(admin);

        assertEq(balanceOfTokens, originalVotingPowerAdmin, "incorrect voting power");

        uint256 originalVotingPowerBeef = veALCX.getVotes(beef);

        assertEq(originalVotingPowerBeef, 0, "should have no voting power");

        hevm.prank(admin);
        veALCX.delegate(beef);

        address delegates = veALCX.delegates(admin);
        assertEq(delegates, beef, "incorrect delegate");

        // Admin should have no power after delegating votes
        uint256 newVotingPowerAdmin = veALCX.getVotes(admin);
        assertEq(newVotingPowerAdmin, 0, "should have no voting power");

        // Beef should now have the voting power of admin's tokens
        uint256 newVotingPowerBeef = veALCX.getVotes(beef);
        assertEq(newVotingPowerBeef, balanceOfTokens, "incorrect voting power");
    }
}
