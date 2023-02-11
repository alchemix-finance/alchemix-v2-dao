// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract VotingEscrowTest is BaseTest {
    uint256 internal constant ONE_WEEK = 1 weeks;
    uint256 maxDuration = ((block.timestamp + MAXTIME) / ONE_WEEK) * ONE_WEEK;

    function setUp() public {
        setupContracts(block.timestamp);
    }

    // Create veALCX
    function testCreateLock() public {
        hevm.startPrank(admin);

        assertEq(veALCX.balanceOf(admin), 0);

        uint256 tokenId = veALCX.createLock(TOKEN_1, ONE_WEEK, false);

        assertEq(veALCX.isApprovedForAll(admin, address(0)), false);
        assertEq(veALCX.getApproved(1), address(0));
        assertEq(veALCX.userPointHistoryTimestamp(1, 1), block.timestamp);

        assertEq(veALCX.ownerOf(tokenId), admin);
        assertEq(veALCX.balanceOf(admin), tokenId);

        hevm.stopPrank();
    }

    // Test depositing, withdrawing from a receiver (Aura pool)
    // TODO update to ALCX Aura pool once deployment is done
    function testReceiver() public {
        deal(testBPT, address(veALCX), TOKEN_1);
        uint256 amount = IERC20(testBPT).balanceOf(address(veALCX));

        assertEq(amount, TOKEN_1);

        uint256 rewardBalanceBefore = IERC20(bal).balanceOf(address(veALCX));

        assertEq(rewardBalanceBefore, 0, "claimed should start at 0");

        veALCX.depositIntoReceiver(amount);

        uint256 amountAfterDeposit = IERC20(testBPT).balanceOf(address(veALCX));

        assertEq(amountAfterDeposit, 0, "full balance should be deposited");

        hevm.warp(block.timestamp + 2 weeks);

        veALCX.claimReceiverRewards();
        uint256 rewardBalanceAfter = IERC20(bal).balanceOf(address(veALCX));

        assertGt(rewardBalanceAfter, rewardBalanceBefore, "should accumulate rewards");

        veALCX.withdrawFromReceiver(amount);

        uint256 amountAfterWithdraw = IERC20(testBPT).balanceOf(address(veALCX));

        assertEq(amountAfterWithdraw, amount, "should equal original amount");
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

        uint256 tokenId1 = veALCX.createLock(TOKEN_1 / 2, ONE_WEEK, false);
        uint256 tokenId2 = veALCX.createLock(TOKEN_1 / 2, ONE_WEEK * 2, false);

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

    // Withdraw enabled after lock expires
    function testWithdraw() public {
        hevm.startPrank(admin);

        uint256 tokenId = veALCX.createLock(TOKEN_1, nextEpoch, false);

        uint256 bptBalanceBefore = IERC20(bpt).balanceOf(admin);

        uint256 fluxBalanceBefore = IERC20(flux).balanceOf(admin);
        uint256 alcxBalanceBefore = IERC20(alcx).balanceOf(admin);

        hevm.expectRevert(abi.encodePacked("Cooldown period has not started"));
        veALCX.withdraw(tokenId);

        voter.reset(tokenId);

        hevm.warp(block.timestamp + nextEpoch);

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

        uint256 tokenId = veALCX.createLock(TOKEN_1, ONE_WEEK, false);

        hevm.expectRevert(abi.encodePacked("Query for nonexistent token"));
        veALCX.tokenURI(999);

        hevm.warp(block.timestamp + ONE_WEEK);
        hevm.roll(block.number + 1);

        // Check that new token doesn't revert
        veALCX.tokenURI(tokenId);

        veALCX.startCooldown(tokenId);

        hevm.warp(block.timestamp + ONE_WEEK);

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
        uint256 tokenId2 = createVeAlcx(admin, TOKEN_100K, nextEpoch, false);

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

    function testRagequit() public {
        hevm.startPrank(admin);

        uint256 tokenId = veALCX.createLock(TOKEN_1, ONE_WEEK, false);

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
