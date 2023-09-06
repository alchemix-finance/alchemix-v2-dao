// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract PassthroughGaugeTest is BaseTest {
    uint256 snapshotWeek = 17120807;

    uint256 platformFee = 400; // 4%
    uint256 DENOMINATOR = 10_000; // denominates weights 10_000 = 100%

    function setUp() public {
        setupContracts(block.timestamp);
    }

    // Rewards should be passed through to external gauges
    // Add tests for gauges as they are added
    function testPassthroughGaugeRewards() public {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        hevm.startPrank(admin);

        uint256 period = minter.activePeriod();

        hevm.warp(period);

        assertEq(sushiGauge.rewardToken(), address(alcx), "incorrect reward token");
        uint256 sushiBalanceBefore = alcx.balanceOf(sushiPoolAddress);

        address[] memory pools = new address[](1);
        pools[0] = sushiPoolAddress;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        // Move forward epoch
        hevm.warp(period + 1 weeks);

        voter.vote(tokenId, pools, weights, 0);

        address[] memory gauges = new address[](1);
        gauges[0] = address(sushiGauge);

        // If testing with votium, warp to "snapshot" to test a valid proposal
        hevm.warp(block.timestamp + nextEpoch);

        // Update gauges to get claimable rewards value
        minter.updatePeriod();
        voter.updateFor(gauges);

        // Claimable rewards of each gauge
        uint256 sushiGaugeClaimable = voter.claimable(address(sushiGauge));

        address[] memory deadGauges = new address[](1);
        deadGauges[0] = address(0);

        hevm.expectRevert(abi.encodePacked("cannot distribute to a dead gauge"));
        voter.distribute(deadGauges);

        voter.distribute(gauges);

        uint256 sushiBalanceAfter = alcx.balanceOf(sushiPoolAddress);

        // Sushi pool ALCX balance should increase by the claimable amount
        assertEq(sushiBalanceAfter - sushiBalanceBefore, sushiGaugeClaimable);

        hevm.stopPrank();
    }

    // Test admin controlled functions
    function testAdminFunctions() public {
        hevm.expectRevert(abi.encodePacked("not admin"));
        sushiGauge.setAdmin(devmsig);

        hevm.expectRevert(abi.encodePacked("not admin"));
        sushiGauge.updateReceiver(devmsig);

        hevm.prank(admin);
        sushiGauge.setAdmin(devmsig);

        hevm.expectRevert(abi.encodePacked("not pending admin"));
        sushiGauge.acceptAdmin();

        hevm.startPrank(devmsig);

        sushiGauge.acceptAdmin();
        sushiGauge.updateReceiver(devmsig);

        hevm.stopPrank();
    }
}
