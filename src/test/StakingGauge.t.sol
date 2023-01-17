// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract StakingGaugeTest is BaseTest {
    uint256 tokenId;

    function setUp() public {
        setupContracts(block.timestamp);

        tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
    }

    function testEmergencyCouncilCanKillAndReviveGauges() public {
        hevm.startPrank(admin);

        address gaugeAddress = address(stakingGauge);

        voter.killGauge(gaugeAddress);
        assertFalse(voter.isAlive(gaugeAddress));

        voter.reviveGauge(gaugeAddress);
        assertTrue(voter.isAlive(gaugeAddress));

        hevm.stopPrank();
    }

    function testFailCouncilCannotKillNonExistentGauge() public {
        hevm.startPrank(admin);

        voter.killGauge(dead);

        hevm.stopPrank();
    }

    function testFailNoOneElseCanKillGauges() public {
        hevm.prank(beef);

        address gaugeAddress = address(stakingGauge);

        voter.killGauge(gaugeAddress);

        // Gauge should still be alive
        assertTrue(voter.isAlive(gaugeAddress));

        hevm.stopPrank();
    }

    function testKilledGaugeCannotDeposit() public {
        hevm.startPrank(admin);

        address gaugeAddress = address(stakingGauge);
        voter.killGauge(gaugeAddress);

        uint256 amount = alcx.balanceOf(admin);
        alcx.approve(gaugeAddress, amount);

        hevm.expectRevert(abi.encodePacked(""));

        stakingGauge.deposit(amount, tokenId);

        hevm.stopPrank();
    }

    function testKilledGaugeCanWithdraw() public {
        hevm.startPrank(admin);

        address gaugeAddress = address(stakingGauge);

        uint256 amount = alcx.balanceOf(admin);
        alcx.approve(gaugeAddress, amount);

        stakingGauge.deposit(amount, tokenId);

        voter.killGauge(gaugeAddress);

        stakingGauge.withdrawToken(amount, tokenId);

        hevm.stopPrank();
    }

    function testKilledGaugeCanUpdateButGoesToZero() public {
        hevm.startPrank(admin);

        hevm.warp(block.timestamp + 86400 * 7 * 2);
        hevm.roll(block.number + 1);

        minter.updatePeriod();
        voter.updateGauge(address(stakingGauge));

        address[] memory gauges = new address[](1);
        gauges[0] = address(stakingGauge);

        voter.killGauge(address(stakingGauge));

        voter.updateFor(gauges);

        assertEq(voter.claimable(address(stakingGauge)), 0);

        hevm.stopPrank();
    }

    function testKilledGaugeCanDistributeButGoesToZero() public {
        hevm.startPrank(admin);

        hevm.warp(block.timestamp + 86400 * 7 * 2);
        hevm.roll(block.number + 1);

        minter.updatePeriod();
        voter.updateGauge(address(stakingGauge));

        address[] memory gauges = new address[](1);
        gauges[0] = address(stakingGauge);

        voter.updateFor(gauges);

        voter.killGauge(address(stakingGauge));

        assertEq(voter.claimable(address(stakingGauge)), 0);

        hevm.stopPrank();
    }

    function testCanStillDistroAllWithKilledGauge() public {
        hevm.startPrank(admin);

        hevm.warp(block.timestamp + 86400 * 7 * 2);
        hevm.roll(block.number + 1);

        minter.updatePeriod();
        voter.updateGauge(address(stakingGauge));
        voter.updateGauge(address(stakingGauge2));

        address[] memory gauges = new address[](2);
        gauges[0] = address(stakingGauge);
        gauges[1] = address(stakingGauge2);

        voter.updateFor(gauges);

        voter.killGauge(address(stakingGauge2));

        // Should be able to claim from stakingGauge
        voter.distro();

        hevm.stopPrank();
    }
}
