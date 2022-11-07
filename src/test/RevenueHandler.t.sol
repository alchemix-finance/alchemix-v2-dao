// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/// @dev See https://onbjerg.github.io/foundry-book/forge/writing-tests.html for details on how this is run
/// @dev See https://onbjerg.github.io/foundry-book/reference/ds-test.html for assertions list
/// @dev See https://onbjerg.github.io/foundry-book/reference/cheatcodes.html for cheatcodes like prank()
/// @dev asserts are (actual, expected)
contract RevenueHandlerTest {
    address holder = 0x000000000000000000000000000000000000dEaD;

    uint256 depositAmount = 999 ether;
    uint256 lockTime = 30 days;

    /// @dev Deploy the contract
    function setUp() public {
        // rh = new RevenueHandler(address(veALCX));
    }

    function testClaimRevenueOneEpoch() external {

    }

    function testClaimRevenueMultipleEpochs() external {

    }

    function testClaimRevenueOtherUserUnlocks() external {

    }

    function testClaimRevenueOtherUserRagequits() external {

    }

    function testFailClaimRevenueTwice() external {
        
    }
}
