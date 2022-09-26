// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract VotingEscrowTest is BaseTest {
    uint256 lockDuration = 1 weeks;
    uint256 depositAmount = 1e21;

    function setUp() public {
        mintAlcx(account, depositAmount);
        approveAmount(account, address(veALCX), depositAmount);
    }

    // Create veALCX
    function testCreateLock() public {
        hevm.startPrank(account);

        assertEq(veALCX.balanceOf(account), 0);

        veALCX.createLock(depositAmount, lockDuration);

        assertEq(veALCX.ownerOf(1), account);
        assertEq(veALCX.balanceOf(account), 1);

        hevm.stopPrank();
    }

    // Locking outside the allowed zones should revert
    function testInvalidLock() public {
        hevm.startPrank(account);

        hevm.expectRevert(abi.encodePacked("Voting lock can be 4 years max"));

        veALCX.createLock(depositAmount, lockDuration + 209 weeks);

        hevm.stopPrank();
    }

    // Votes should increase as veALCX is created
    function testVotes() public {
        hevm.startPrank(account);

        uint256 tokenId = veALCX.createLock(depositAmount, lockDuration);

        uint256 votes = veALCX.balanceOfAtNFT(tokenId, block.number);
        uint256 totalVotes = veALCX.totalSupply();

        assertEq(totalVotes, votes, "votes doesn't match total");

        hevm.stopPrank();
    }

    // Withdraw enabled after lock expires
    function testWithdraw() public {
        hevm.startPrank(account);

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

    // Calling tokenURI should not work for non-existent token ids
    function testTokenURICalls() public {
        hevm.startPrank(account);

        veALCX.createLock(depositAmount, lockDuration);

        hevm.expectRevert(abi.encodePacked("Query for nonexistent token"));
        veALCX.tokenURI(999);

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
}
