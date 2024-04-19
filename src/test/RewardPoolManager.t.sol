// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract RewardPoolManagerTest is BaseTest {
    function setUp() public {
        setupContracts(block.timestamp);
    }

    function testAdminFunctions() public {
        address admin = rewardPoolManager.admin();

        hevm.expectRevert(abi.encodePacked("not admin"));
        rewardPoolManager.setAdmin(devmsig);

        hevm.prank(admin);
        hevm.expectRevert(abi.encodePacked("not pending admin"));
        rewardPoolManager.acceptAdmin();

        hevm.expectRevert(abi.encodePacked("not admin"));
        rewardPoolManager.setTreasury(devmsig);

        hevm.expectRevert(abi.encodePacked("not admin"));
        rewardPoolManager.setRewardPool(devmsig);

        hevm.expectRevert(abi.encodePacked("not admin"));
        rewardPoolManager.setPoolToken(devmsig);

        hevm.expectRevert(abi.encodePacked("not admin"));
        rewardPoolManager.setVeALCX(devmsig);

        hevm.prank(admin);
        rewardPoolManager.setAdmin(devmsig);

        hevm.startPrank(devmsig);
        rewardPoolManager.acceptAdmin();

        rewardPoolManager.setTreasury(devmsig);

        rewardPoolManager.setRewardPool(devmsig);

        rewardPoolManager.setPoolToken(address(usdc));

        rewardPoolManager.setVeALCX(address(minter));

        hevm.stopPrank();
    }

    function testDepositIntoRewardPoolError() public {
        hevm.expectRevert(abi.encodePacked("must be veALCX"));
        rewardPoolManager.depositIntoRewardPool(TOKEN_1);
    }

    function testWithdrawFromRewardPool() public {
        hevm.expectRevert(abi.encodePacked("must be veALCX"));
        rewardPoolManager.withdrawFromRewardPool(1000);
    }

    // Test depositing, withdrawing from a rewardPool (Aura pool)
    function testRewardPool() public {
        // Reward pool should be set
        assertEq(rewardPool, rewardPoolManager.rewardPool());

        deal(bpt, address(rewardPoolManager), TOKEN_1);

        // Initial amount of bal and aura rewards earned
        uint256 rewardBalanceBefore1 = IERC20(bal).balanceOf(admin);
        uint256 rewardBalanceBefore2 = IERC20(aura).balanceOf(admin);
        assertEq(rewardBalanceBefore1, 0, "rewardBalanceBefore1 should be 0");
        assertEq(rewardBalanceBefore2, 0, "rewardBalanceBefore2 should be 0");

        // Initial BPT balance of rewardPoolManager
        uint256 amount = IERC20(bpt).balanceOf(address(rewardPoolManager));
        assertEq(amount, TOKEN_1);

        // Deposit BPT balance into rewardPool
        hevm.prank(address(veALCX));
        rewardPoolManager.depositIntoRewardPool(amount);

        uint256 amountAfterDeposit = IERC20(bpt).balanceOf(address(rewardPoolManager));
        assertEq(amountAfterDeposit, 0, "full balance should be deposited");

        uint256 rewardPoolBalance = IRewardPool4626(rewardPool).balanceOf(address(rewardPoolManager));
        assertEq(rewardPoolBalance, amount, "rewardPool balance should equal amount deposited");

        // Fast forward to accumulate rewards
        hevm.warp(block.timestamp + 2 weeks);

        hevm.expectRevert(abi.encodePacked("not admin"));
        rewardPoolManager.claimRewardPoolRewards();

        hevm.prank(admin);
        rewardPoolManager.claimRewardPoolRewards();
        uint256 rewardBalanceAfter1 = IERC20(bal).balanceOf(address(admin));
        uint256 rewardBalanceAfter2 = IERC20(aura).balanceOf(address(admin));

        // After claiming rewards admin bal balance should increase
        assertGt(rewardBalanceAfter1, rewardBalanceBefore1, "should accumulate bal rewards");
        assertGt(rewardBalanceAfter2, rewardBalanceBefore2, "should accumulate aura rewards");

        hevm.prank(address(veALCX));
        rewardPoolManager.withdrawFromRewardPool(amount);

        // veALCX BPT balance should equal original amount after withdrawing from rewardPool
        uint256 amountAfterWithdraw = IERC20(bpt).balanceOf(address(veALCX));
        assertEq(amountAfterWithdraw, amount, "should equal original amount");

        // Only rewardPoolManager admin can update rewardPool
        hevm.expectRevert(abi.encodePacked("not admin"));
        rewardPoolManager.setRewardPool(sushiPoolAddress);

        hevm.prank(admin);
        rewardPoolManager.setRewardPool(sushiPoolAddress);

        // Reward pool should update
        assertEq(sushiPoolAddress, rewardPoolManager.rewardPool(), "rewardPool not updated");
    }

    function testUpdatingRewardPoolTokens() public {
        address admin = rewardPoolManager.admin();

        address[] memory tokens = new address[](2);
        tokens[0] = dai;
        tokens[1] = usdt;

        hevm.expectRevert(abi.encodePacked("not admin"));
        rewardPoolManager.swapOutRewardPoolToken(0, bal, usdc);

        hevm.expectRevert(abi.encodePacked("not admin"));
        rewardPoolManager.addRewardPoolTokens(tokens);

        hevm.expectRevert(abi.encodePacked("not admin"));
        rewardPoolManager.addRewardPoolToken(dai);

        hevm.startPrank(admin);

        hevm.expectRevert(abi.encodePacked("incorrect token"));
        rewardPoolManager.swapOutRewardPoolToken(0, dai, usdc);

        rewardPoolManager.swapOutRewardPoolToken(0, bal, usdc);
        assertEq(rewardPoolManager.rewardPoolTokens(0), usdc, "rewardPoolTokens[0] should be usdc");

        rewardPoolManager.addRewardPoolTokens(tokens);
        assertEq(rewardPoolManager.rewardPoolTokens(2), dai, "rewardPoolTokens[2] should be dai");
        assertEq(rewardPoolManager.rewardPoolTokens(3), usdt, "rewardPoolTokens[3] should be usdt");
    }

    function testMaxRewardPoolTokens() public {
        address[] memory tokens = new address[](8);
        tokens[0] = dai;
        tokens[1] = usdt;
        tokens[2] = usdc;
        tokens[3] = bpt;
        tokens[4] = time;
        tokens[5] = aleth;
        tokens[6] = alusd3crv;
        tokens[7] = alusd;

        hevm.prank(admin);
        rewardPoolManager.addRewardPoolTokens(tokens);

        hevm.prank(admin);
        hevm.expectRevert(abi.encodePacked("too many reward pool tokens"));
        rewardPoolManager.addRewardPoolToken(beef);
    }
}
