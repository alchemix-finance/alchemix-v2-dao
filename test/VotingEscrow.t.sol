// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract VotingEscrowTest is BaseTest {
    uint256 internal constant ONE_WEEK = 1 weeks;
    uint256 maxDuration = ((block.timestamp + MAXTIME) / ONE_WEEK) * ONE_WEEK;

    function setUp() public {
        setupBaseTest();

        approveAmount(admin, address(veALCX), TOKEN_1);
    }

    // Create veALCX
    function testCreateLock() public {
        hevm.startPrank(admin);

        assertEq(veALCX.balanceOf(admin), 0);

        veALCX.createLock(TOKEN_1, ONE_WEEK, false);

        assertEq(veALCX.ownerOf(1), admin);
        assertEq(veALCX.balanceOf(admin), 1);

        hevm.stopPrank();
    }

    function testUpdateLockDuration() public {
        hevm.startPrank(admin);

        veALCX.createLock(TOKEN_1, 5 weeks, true);

        uint256 lockEnd = veALCX.lockEnd(1);

        // Lock end should be max time when max lock is enabled
        assertEq(lockEnd, maxDuration);

        veALCX.updateUnlockTime(1, 1 days, true);

        lockEnd = veALCX.lockEnd(1);

        // Lock duration should be unchanged
        assertEq(lockEnd, maxDuration);

        veALCX.updateUnlockTime(1, 1 days, false);

        lockEnd = veALCX.lockEnd(1);

        // Lock duration should be unchanged
        assertEq(lockEnd, maxDuration);

        // Now that max lock is disabled lock duration can be set again
        hevm.expectRevert(abi.encodePacked("Voting lock can be 1 year max"));

        veALCX.updateUnlockTime(1, MAXTIME + ONE_WEEK, false);

        hevm.warp(block.timestamp + 260 days);

        lockEnd = veALCX.lockEnd(1);

        // Able to increase lock end now that previous lock end is closer
        veALCX.updateUnlockTime(1, 200 days, false);

        // Updated lock end should be greater than previous lockEnd
        assertGt(veALCX.lockEnd(1), lockEnd);

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

        uint256 votingPower = veALCX.balanceOfToken(tokenId1) + veALCX.balanceOfToken(tokenId2);

        assertEq(votingPower, totalVotes, "votes doesn't match total");

        assertEq(votingPower, maxVotingPower, "votes doesn't match total");

        hevm.stopPrank();
    }

    // Withdraw enabled after lock expires
    function testWithdraw() public {
        hevm.startPrank(admin);

        uint256 tokenId = veALCX.createLock(TOKEN_1, ONE_WEEK, false);

        hevm.expectRevert(abi.encodePacked("Cooldown period has not started"));
        veALCX.withdraw(tokenId);

        hevm.warp(block.timestamp + ONE_WEEK);

        // Start cooldown once lock is expired
        veALCX.startCooldown(tokenId);

        hevm.expectRevert(abi.encodePacked("Cooldown period in progress"));
        veALCX.withdraw(tokenId);

        hevm.warp(block.timestamp + ONE_WEEK);
        hevm.roll(block.number + 1);
        veALCX.withdraw(tokenId);

        assertEq(alcx.balanceOf(address(admin)), TOKEN_1);

        // Check that the token is burnt
        assertEq(veALCX.balanceOfToken(tokenId), 0);
        assertEq(veALCX.ownerOf(tokenId), address(0));

        hevm.stopPrank();
    }

    // Calling tokenURI should not work for non-existent token ids
    function testTokenURICalls() public {
        hevm.startPrank(admin);

        veALCX.createLock(TOKEN_1, ONE_WEEK, false);

        hevm.expectRevert(abi.encodePacked("Query for nonexistent token"));
        veALCX.tokenURI(999);

        uint256 tokenId = 1;
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

    function testRagequit() public {
        hevm.startPrank(admin);

        uint256 tokenId = veALCX.createLock(TOKEN_1, ONE_WEEK, false);

        // Show that veALCX is not expired
        hevm.expectRevert(abi.encodePacked("Cooldown period has not started"));
        veALCX.withdraw(tokenId);

        // admin doesn't have enough MANA
        hevm.expectRevert(abi.encodePacked("insufficient MANA balance"));
        veALCX.startCooldown(tokenId);

        hevm.stopPrank();

        uint256 ragequitAmount = veALCX.amountToRagequit(tokenId);

        // Mint the necessary amount of MANA to ragequit
        mintMana(admin, ragequitAmount);

        hevm.startPrank(admin);

        MANA.approve(address(veALCX), ragequitAmount);

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
