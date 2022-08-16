// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/console2.sol";
import "./BaseTest.sol";

contract VotingEscrowTest is BaseTest {
    VotingEscrow veALCX;

    function setUp() public {
        mintAlcx(1e21);
        veALCX = new VotingEscrow(address(alcx));
    }

    function testCreateLock() public {
        uint256 lockDuration = 7 days;
        uint256 depositAmount = 1e21;

        hevm.startPrank(account);

        alcx.approve(address(veALCX), depositAmount);

        assertEq(veALCX.balanceOf(account), 0);

        veALCX.createLock(depositAmount, lockDuration);

        assertEq(veALCX.ownerOf(1), account);
        assertEq(veALCX.balanceOf(account), 1);

        hevm.stopPrank();
    }

    function testCreateLockOutsideZones() public {
        uint256 lockDuration = 1467 days;
        uint256 depositAmount = 1e21;

        hevm.startPrank(account);

        alcx.approve(address(veALCX), depositAmount);

        hevm.expectRevert(abi.encodePacked("Voting lock can be 4 years max"));

        veALCX.createLock(depositAmount, lockDuration);

        hevm.stopPrank();
    }

    function testVEALCXVotingPower() public {
        uint256 lockDuration = 30 days;
        uint256 depositAmount = 1e21;

        hevm.startPrank(account);

        alcx.approve(address(veALCX), depositAmount);
        uint256 tokenId = veALCX.createLock(depositAmount, lockDuration);

        // Get voting power
        uint256 votes = veALCX.balanceOfAtNFT(tokenId, block.number);
        // Get total voting power
        uint256 totalVotes = veALCX.totalSupply();

        assertEq(totalVotes, votes, "votes doesn't match total");

        hevm.stopPrank();
    }

    function testWithdraw() public {
        uint256 lockDuration = 1 weeks;
        uint256 depositAmount = 1e21;

        hevm.startPrank(account);

        alcx.approve(address(veALCX), depositAmount);
        uint256 tokenId = veALCX.createLock(depositAmount, lockDuration);

        hevm.expectRevert(abi.encodePacked("The lock didn't expire"));

        veALCX.withdraw(tokenId);

        hevm.warp(block.timestamp + lockDuration);
        hevm.roll(block.number + 1);
        veALCX.withdraw(tokenId);

        assertEq(alcx.balanceOf(address(account)), 1e21);

        // Check that the NFT is burnt
        assertEq(veALCX.balanceOfNFT(tokenId), 0);
        assertEq(veALCX.ownerOf(tokenId), address(0));

        hevm.stopPrank();
    }

    function testCheckTokenURICalls() public {
        uint256 lockDuration = 1 weeks;
        uint256 depositAmount = 1e21;

        // tokenURI should not work for non-existent token ids
        hevm.startPrank(account);

        hevm.expectRevert(abi.encodePacked("Query for nonexistent token"));
        veALCX.tokenURI(999);

        alcx.approve(address(veALCX), depositAmount);
        veALCX.createLock(depositAmount, lockDuration);

        uint256 tokenId = 1;
        hevm.warp(block.timestamp + lockDuration);
        hevm.roll(block.number + 1);

        // Check that new token doesn't revert
        veALCX.tokenURI(tokenId);

        // Withdraw, which destroys the NFT
        veALCX.withdraw(tokenId);

        // tokenURI should not work for this anymore as the NFT is burnt
        hevm.expectRevert(abi.encodePacked("Query for nonexistent token"));
        veALCX.tokenURI(tokenId);

        hevm.stopPrank();
    }

    function testSupportedInterfaces() public {
        // Check that it supports all the asserted interfaces.
        bytes4 ERC165_INTERFACE_ID = 0x01ffc9a7;
        bytes4 ERC721_INTERFACE_ID = 0x80ac58cd;
        bytes4 ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;

        assertTrue(veALCX.supportsInterface(ERC165_INTERFACE_ID));
        assertTrue(veALCX.supportsInterface(ERC721_INTERFACE_ID));
        assertTrue(veALCX.supportsInterface(ERC721_METADATA_INTERFACE_ID));
    }

    function testUnsupportedInterfaces() public {
        bytes4 ERC721_FAKE = 0x780e9d61;
        assertFalse(veALCX.supportsInterface(ERC721_FAKE));
    }
}
