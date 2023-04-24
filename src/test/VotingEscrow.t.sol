// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract VotingEscrowTest is BaseTest {
    uint256 internal constant ONE_WEEK = 1 weeks;
    uint256 internal constant THREE_WEEKS = 3 weeks;
    uint256 internal constant FOUR_WEEKS = 4 weeks;
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

    // Test depositing, withdrawing from a rewardPool (Aura pool)
    // TODO update to ALCX Aura pool once deployment is done
    function testRewardPool() public {
        deal(bpt, address(veALCX), TOKEN_1);
        deal(bal, address(rewardPool), TOKEN_100K);

        hevm.prank(address(veALCX));
        MockCurveGauge(rewardPool).set_rewards_receiver(address(veALCX));

        // Initial BPT balance of veALCX
        uint256 amount = IERC20(bpt).balanceOf(address(veALCX));
        assertEq(amount, TOKEN_1);

        // Inital amount of bal rewards veALCX contract has earned
        uint256 rewardBalanceBefore = IERC20(bal).balanceOf(address(veALCX));
        assertEq(rewardBalanceBefore, 0, "reward balance should be 0");

        // Deposit BPT balance into rewardPool
        veALCX.depositIntoRewardPool(amount);

        uint256 amountAfterDeposit = IERC20(bpt).balanceOf(address(veALCX));
        assertEq(amountAfterDeposit, 0, "full balance should be deposited");

        // Fast forward to accumulate rewards
        hevm.warp(block.timestamp + 2 weeks);

        veALCX.claimRewardPoolRewards();
        uint256 rewardBalanceAfter = IERC20(bal).balanceOf(address(veALCX));

        // After claiming rewards veALCX bal balance should increase
        assertGt(rewardBalanceAfter, rewardBalanceBefore, "should accumulate rewards");

        veALCX.withdrawFromRewardPool(amount);

        // veALCX BPT balance should equal original amount after withdrawing from rewardPool
        uint256 amountAfterWithdraw = IERC20(bpt).balanceOf(address(veALCX));
        assertEq(amountAfterWithdraw, amount, "should equal original amount");

        // Reward pool should be set
        assertEq(rewardPool, veALCX.rewardPool());

        // Only veALCX admin can update rewardPool
        hevm.prank(admin);
        hevm.expectRevert(abi.encodePacked("not admin"));
        veALCX.updateRewardPool(sushiPoolAddress);

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
        hevm.startPrank(admin);

        uint256 tokenId1 = veALCX.createLock(TOKEN_1 / 2, THREE_WEEKS, false);
        uint256 tokenId2 = veALCX.createLock(TOKEN_1 / 2, THREE_WEEKS * 2, false);

        uint256 maxVotingPower = getMaxVotingPower(TOKEN_1 / 2, veALCX.lockEnd(tokenId1)) +
            getMaxVotingPower(TOKEN_1 / 2, veALCX.lockEnd(tokenId2));

        uint256 totalVotes = veALCX.totalSupply();

        uint256 totalVotesAt = veALCX.totalSupplyAt(block.number);

        assertEq(totalVotes, totalVotesAt);

        uint256 votingPower = veALCX.balanceOfToken(tokenId1) + veALCX.balanceOfToken(tokenId2);

        assertEq(votingPower, totalVotes, "votes doesn't match total");

        assertEq(votingPower, maxVotingPower, "votes doesn't match total");

        hevm.stopPrank();
    }

    // Test tracking of checkpoints and calculating votes at points in time
    function testPastVotesIndex() public {
        uint256 voteTimestamp0 = block.timestamp;

        hevm.startPrank(admin);

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
        uint256 tokenId2 = createVeAlcx(admin, TOKEN_100K, THREE_WEEKS, false);

        hevm.startPrank(admin);

        assertEq(veALCX.lockEnd(tokenId1), ((block.timestamp + MAXTIME) / 1 weeks) * 1 weeks);
        assertEq(veALCX.lockedAmount(tokenId1), TOKEN_1);

        hevm.expectRevert(abi.encodePacked("must be different tokens"));
        veALCX.merge(tokenId1, tokenId1);

        veALCX.merge(tokenId1, tokenId2);

        // Merged token should take longer of the two lock end dates
        assertEq(veALCX.lockEnd(tokenId2), ((block.timestamp + MAXTIME) / 1 weeks) * 1 weeks);

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
        uint256 tokenId3 = createVeAlcx(admin, TOKEN_1, FOUR_WEEKS, false);
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
}
