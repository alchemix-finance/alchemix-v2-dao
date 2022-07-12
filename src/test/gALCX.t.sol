// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {DSTest} from "ds-test/test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {gALCX} from "../gALCX.sol";
import {IALCXSource} from "../interfaces/IALCXSource.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {Hevm} from "./utils/Hevm.sol";
import {ALCXSource} from "./mocks/ALCXSource.sol";

interface Vm {
    function prank(address) external;
}

/// @dev See https://onbjerg.github.io/foundry-book/forge/writing-tests.html for details on how this is run
/// @dev See https://onbjerg.github.io/foundry-book/reference/ds-test.html for assertions list
/// @dev See https://onbjerg.github.io/foundry-book/reference/cheatcodes.html for cheatcodes like prank()
/// @dev asserts are (actual, expected)
contract gALCXTest is DSTestPlus {
    IERC20 public alcx = IERC20(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
    IALCXSource internal constant pool = IALCXSource(0xAB8e74017a8Cc7c15FFcCd726603790d26d7DeCa);
    address holder = 0x000000000000000000000000000000000000dEaD;
    gALCX govALCX;

    uint depositAmount = 999 ether;

    /// @dev Deploy the contract
    function setUp() public {
        uint foo = 3;
        assertGt(foo, 2);
        govALCX = new gALCX("governance ALCX", "gALCX");
    }

    /// @dev Deposit ALCX into gALCX
    function testStake() public {
        hevm.startPrank(holder);
        uint oldBalance = alcx.balanceOf(holder);
        uint amount = depositAmount;
        bool success = alcx.approve(address(govALCX), amount);
        assertTrue(success);
        govALCX.stake(amount);
        uint gBalance = govALCX.balanceOf(holder);
        uint newBalance = alcx.balanceOf(holder);
        assertEq(gBalance, amount);
        assertEq(oldBalance-newBalance, amount);
        hevm.stopPrank();
    }

    /// @dev Fuzz staking with a variety of staking amounts
    function testStakeFuzz(uint amount) public {
        // Constrain the param to lie within user balance
        amount = bound(amount, 0, alcx.balanceOf(holder));

        hevm.startPrank(holder);
        bool success = alcx.approve(address(govALCX), amount);
        assertTrue(success);
        govALCX.stake(amount);
        uint gBalance = govALCX.balanceOf(holder);
        assertEq(gBalance, amount);
        hevm.stopPrank();
    }

    /// @dev Check if reverts when you try to stake more than approved
    function testFailStake() public {
        hevm.startPrank(holder);
        uint amount = depositAmount;
        bool success = alcx.approve(address(govALCX), amount);
        assertTrue(success);
        govALCX.stake(amount+1);
    }

    /// @dev Deposit ALCX into gALCX, then withdraw
    function testStakeAndUnstake() public {
        testStake();
        hevm.startPrank(holder);
        uint gBalance = govALCX.balanceOf(holder);
        uint prevBalance = alcx.balanceOf(holder);
        govALCX.unstake(gBalance);
        uint balance = alcx.balanceOf(holder);
        // Check that ALCX diff equals the old gALCX balance
        assertEq(gBalance, balance-prevBalance);
        hevm.stopPrank();
    }

    /// @dev Deposit ALCX into gALCX, then fail to withdraw more than your gALCX amount
    function testFailStakeAndUnstake() public {
        testStake();
        hevm.startPrank(holder);
        uint gBalance = govALCX.balanceOf(holder);
        govALCX.unstake(gBalance+1);
    }

    /// @dev Deposit, then rebase upwards, then withdraw
    function testStakeAndRebaseAndUnstake() public {
        testStake();
        uint oldExchangeRate = govALCX.exchangeRate();
        hevm.startPrank(holder);
        // Send ALCX to the StakingPool, mocking reward distribution
        uint rewardAmount = 100000 ether;
        alcx.approve(address(pool), rewardAmount);
        pool.deposit(1, rewardAmount);
        // Time travel one block, IALCXSource has some equality defaults
        hevm.warp(block.timestamp + 13);
        hevm.roll(block.number + 1);
        // Now check the new exchange rate
        govALCX.bumpExchangeRate();
        uint newExchangeRate = govALCX.exchangeRate();
        assertGt(newExchangeRate, oldExchangeRate);
        // Unstake
        uint oldBalance = alcx.balanceOf(holder);
        uint gBalance = govALCX.balanceOf(holder);
        govALCX.unstake(gBalance);
        uint newBalance = alcx.balanceOf(holder);
        assertGt(newBalance-oldBalance, depositAmount);
    }

    function testMigrateSource() public returns (ALCXSource) {
        testStake();
        address owner = govALCX.owner();
        assertEq(owner, address(this));
        // Deploy a new source
        ALCXSource alcxSource = new ALCXSource();
        // Migrate to the new source
        govALCX.migrateSource(address(alcxSource), 1);
        uint sourceBalance = alcxSource.balances(address(govALCX));
        assertEq(sourceBalance, depositAmount);
        return alcxSource;
    }

    function testMigrateSourceAndUnstake() public {
        testMigrateSource();
        hevm.startPrank(holder);
        uint oldBalance = alcx.balanceOf(holder);
        uint gBalance = govALCX.balanceOf(holder);
        govALCX.unstake(gBalance);
        uint newBalance = alcx.balanceOf(holder);
        assertEq(newBalance-oldBalance, gBalance);
    }

}
