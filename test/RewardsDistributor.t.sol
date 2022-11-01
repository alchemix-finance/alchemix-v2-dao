// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract RewardsDistributorTest is BaseTest {
    address holder = 0x000000000000000000000000000000000000dEaD;
    RewardsDistributor distributor;

    uint256 depositAmount = 999 ether;
    uint256 lockTime = 30 days;

    /// @dev Deploy the contract
    function setUp() public {
        distributor = new RewardsDistributor(address(veALCX), address(weth), address(balancerVault), priceFeed);
    }

    function testRewardsDistributorSetup() public view {
        console2.log(address(distributor));
    }

    // /// @dev Deposit ALCX into a veALCX token and read parameters
    // function testVEALCXBasic() public {
    //     hevm.startPrank(holder);
    //     uint256 alcxBalance = alcx.balanceOf(holder);
    //     assertGt(alcxBalance, depositAmount, "Not enough alcx");

    //     IERC20(bpt).approve(address(veALCX), depositAmount);
    //     uint256 tokenId = veALCX.createLock(depositAmount, lockTime, false);

    //     // Check that veALCX was created
    //     address owner = veALCX.ownerOf(tokenId);
    //     assertEq(owner, holder);

    //     // Check veALCX parameters
    //     // LockedBalance memory bal = veALCX.locked(tokenId);
    //     (int256 amount, uint256 end) = veALCX.locked(tokenId);
    //     assertEq(uint256(amount), depositAmount, "depositAmount doesn't match");
    //     assertLe(end, block.timestamp + lockTime, "lockTime doesn't match"); // Rounds to nearest week
    // }
}
