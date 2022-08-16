// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import { ve, LockedBalance } from "../src/veALCX.sol";

import "forge-std/console2.sol";

import { DSTest } from "ds-test/test.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IERC20Mintable } from "../src/interfaces/IERC20Mintable.sol";
import { IAlchemixToken } from "../src/interfaces/IAlchemixToken.sol";
import { DSTestPlus } from "./utils/DSTestPlus.sol";

contract veALCXTest is DSTestPlus {
    IAlchemixToken public alcx = IAlchemixToken(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
    IERC20 public galcx = IERC20(0x93Dede06AE3B5590aF1d4c111BC54C3f717E4b35);
    address holder = address(0xbeef);
    address constant admin = 0x8392F6669292fA56123F71949B52d883aE57e225;

    ve veALCX;

    uint256 depositAmount = 999 ether;
    uint256 lockTime = 30 days;

    /// @dev Deploy the contract
    function setUp() public {
        veALCX = new ve(address(alcx));

        hevm.startPrank(admin);
        alcx.grantRole(keccak256("MINTER"), address(admin));
        alcx.mint(holder, 1e21);
        hevm.stopPrank();
    }

    /// @dev Deposit ALCX into a veALCX NFT and read parameters
    function testVEALCXBasic() public {
        hevm.startPrank(holder);

        uint256 alcxBalance = alcx.balanceOf(holder);
        assertGt(alcxBalance, depositAmount, "Not enough alcx");

        alcx.approve(address(veALCX), depositAmount);
        uint256 tokenId = veALCX.createLock(depositAmount, lockTime);

        // Check that veNFT was created
        // address owner = veALCX.ownerOf(tokenId);
        // assertEq(owner, holder);

        // Check veNFT parameters
        // LockedBalance memory bal = veALCX.locked(tokenId);
        // (int128 amount, uint256 end) = veALCX.locked(tokenId);
        // assertEq(uint256(uint128(amount)), depositAmount, "depositAmount doesn't match");
        // assertLe(end, block.timestamp + lockTime, "lockTime doesn't match"); // Rounds to nearest week
    }

    // function testCreateLock() public {
    //     uint256 lockDuration = 7 days;
    //     uint256 depositAmount = 999 ether;
    //     console2.log("~ depositAmount", depositAmount); // 999000000000000000000
    //     console2.log("~ 1e21", 1e21); // 1000000000000000000000
    //     uint256 balance = alcx.balanceOf(holder); // 1000000000000000000000
    //     console2.log("~ balance", balance);

    //     assertEq(veALCX.balanceOf(holder), 0);
    //     veALCX.createLock(1e18, lockDuration);
    // }

    // /// @dev Create veNFT and query voting power
    // function testVEALCXVotingPower() public {
    //     hevm.startPrank(holder);

    //     alcx.approve(address(veALCX), depositAmount);
    //     uint256 tokenId = veALCX.createLock(depositAmount, lockTime);

    //     // Get voting power
    //     uint256 votes = veALCX.balanceOfAtNFT(tokenId, block.number);
    //     assertGt(votes, 1 ether, "voting power too low");
    //     assertLt(votes, depositAmount, "voting power too high");

    //     // Get total voting power
    //     uint256 totalVotes = veALCX.totalSupply();
    //     assertEq(totalVotes, votes, "votes doesn't match total");
    // }
}
