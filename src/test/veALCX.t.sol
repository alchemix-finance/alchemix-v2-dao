// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {LockedBalance} from "../veALCX.sol";

import "forge-std/console2.sol";
import {DSTest} from "ds-test/test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {ve} from "../veALCX.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {Hevm} from "./utils/Hevm.sol";

interface Vm {
    function prank(address) external;
}

/// @dev See https://onbjerg.github.io/foundry-book/forge/writing-tests.html for details on how this is run
/// @dev See https://onbjerg.github.io/foundry-book/reference/ds-test.html for assertions list
/// @dev See https://onbjerg.github.io/foundry-book/reference/cheatcodes.html for cheatcodes like prank()
/// @dev asserts are (actual, expected)
contract veALCXTest is DSTestPlus {
    IERC20 public alcx = IERC20(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
    IERC20 public galcx = IERC20(0x93Dede06AE3B5590aF1d4c111BC54C3f717E4b35);
    address holder = 0x000000000000000000000000000000000000dEaD;
    ve veALCX;

    uint depositAmount = 999 ether;
    uint lockTime = 30 days;

    /// @dev Deploy the contract
    function setUp() public {
        veALCX = new ve(address(alcx));
    }

    /// @dev Deposit ALCX into a veALCX NFT and read parameters
    function testVEALCXBasic() public {
        hevm.startPrank(holder);
        uint alcxBalance = alcx.balanceOf(holder);
        assertGt(alcxBalance, depositAmount, "Not enough alcx");

        alcx.approve(address(veALCX), depositAmount);
        uint tokenId = veALCX.create_lock(depositAmount, lockTime);

        // Check that veNFT was created
        address owner = veALCX.ownerOf(tokenId);
        assertEq(owner, holder);

        // Check veNFT parameters
        // LockedBalance memory bal = veALCX.locked(tokenId);
        (int128 amount, uint end) = veALCX.locked(tokenId);
        assertEq(uint(uint128(amount)), depositAmount, "depositAmount doesn't match");
        assertLe(end, block.timestamp + lockTime, "lockTime doesn't match"); // Rounds to nearest week
    }

    /// @dev Create veNFT and query voting power
    function testVEALCXVotingPower() public {
        hevm.startPrank(holder);

        alcx.approve(address(veALCX), depositAmount);
        uint tokenId = veALCX.create_lock(depositAmount, lockTime);

        // Get voting power
        uint votes = veALCX.balanceOfAtNFT(tokenId, block.number);
        assertGt(votes, 1 ether, "voting power too low");
        assertLt(votes, depositAmount, "voting power too high");

        // Get total voting power
        uint totalVotes = veALCX.totalSupply();
        assertEq(totalVotes, votes, "votes doesn't match total");

        // console2.log(votes / 1 ether);
    }


}
