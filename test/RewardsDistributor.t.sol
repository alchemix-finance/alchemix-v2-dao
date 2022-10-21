// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./BaseTest.sol";

/// @dev See https://onbjerg.github.io/foundry-book/forge/writing-tests.html for details on how this is run
/// @dev See https://onbjerg.github.io/foundry-book/reference/ds-test.html for assertions list
/// @dev See https://onbjerg.github.io/foundry-book/reference/cheatcodes.html for cheatcodes like prank()
/// @dev asserts are (actual, expected)
contract RewardsDistributorTest is BaseTest {
    address holder = 0x000000000000000000000000000000000000dEaD;
    RewardsDistributor distributor;

    uint256 depositAmount = 999 ether;
    uint256 lockTime = 30 days;

    /// @dev Deploy the contract
    function setUp() public {
        distributor = new RewardsDistributor(address(veALCX));
    }

    function testRewardsDistributorSetup() public view {
        console2.log(address(distributor));
    }

    // /// @dev Deposit ALCX into a veALCX NFT and read parameters
    // function testVEALCXBasic() public {
    //     hevm.startPrank(holder);
    //     uint256 alcxBalance = alcx.balanceOf(holder);
    //     assertGt(alcxBalance, depositAmount, "Not enough alcx");

    //     alcx.approve(address(veALCX), depositAmount);
    //     uint256 tokenId = veALCX.createLock(depositAmount, lockTime, false);

    //     // Check that veNFT was created
    //     address owner = veALCX.ownerOf(tokenId);
    //     assertEq(owner, holder);

    //     // Check veNFT parameters
    //     // LockedBalance memory bal = veALCX.locked(tokenId);
    //     (int256 amount, uint256 end) = veALCX.locked(tokenId);
    //     assertEq(uint256(amount), depositAmount, "depositAmount doesn't match");
    //     assertLe(end, block.timestamp + lockTime, "lockTime doesn't match"); // Rounds to nearest week
    // }
}
