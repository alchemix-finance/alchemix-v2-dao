// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import { ve, LockedBalance } from "../src/veALCX.sol";
import { Voter } from "../src/Voter.sol";
import { PairFactory } from "../src/factories/PairFactory.sol";
import { GaugeFactory } from "../src/factories/GaugeFactory.sol";
import { BribeFactory } from "../src/factories/BribeFactory.sol";

import "forge-std/console2.sol";
import { DSTest } from "ds-test/test.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import { DSTestPlus } from "./utils/DSTestPlus.sol";
import { Hevm } from "./utils/Hevm.sol";

interface Vm {
    function prank(address) external;
}

/// @dev See https://onbjerg.github.io/foundry-book/forge/writing-tests.html for details on how this is run
/// @dev See https://onbjerg.github.io/foundry-book/reference/ds-test.html for assertions list
/// @dev See https://onbjerg.github.io/foundry-book/reference/cheatcodes.html for cheatcodes like prank()
/// @dev asserts are (actual, expected)
contract VotingTest is DSTestPlus {
    IERC20 public alcx = IERC20(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
    IERC20 public galcx = IERC20(0x93Dede06AE3B5590aF1d4c111BC54C3f717E4b35);
    address holder = 0x000000000000000000000000000000000000dEaD;
    ve veALCX;
    Voter voter;
    PairFactory pairFactory;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;

    uint256 depositAmount = 999 ether;
    uint256 lockTime = 30 days;

    /// @dev Deploy the contract
    function setUp() public {
        veALCX = new ve(address(alcx));
        pairFactory = new PairFactory();
        gaugeFactory = new GaugeFactory(address(pairFactory));
        bribeFactory = new BribeFactory();
        voter = new Voter(address(veALCX), address(gaugeFactory), address(bribeFactory));

        // Create veNFT for `holder`
        hevm.startPrank(holder);
        assertGt(alcx.balanceOf(holder), depositAmount, "Not enough alcx");

        alcx.approve(address(veALCX), depositAmount);
        uint256 tokenId = veALCX.createLock(depositAmount, lockTime);

        // Check that veNFT was created
        address owner = veALCX.ownerOf(tokenId);
        assertEq(owner, holder);

        // Check veNFT parameters
        (int128 amount, uint256 end) = veALCX.locked(tokenId);
        hevm.stopPrank();
    }

    /// @dev Vote on a gauge using the veNFT
    function testVote() public {}
}
