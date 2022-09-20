// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract StakingGaugeTest is BaseTest {
    VotingEscrow veALCX;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    Voter voter;
    RewardsDistributor distributor;
    Minter minter;
    StakingGauge gauge;
    StakingGauge gauge2;

    function setUp() public {
        mintAlcx(admin, 1e25);

        hevm.startPrank(admin);

        veALCX = new VotingEscrow(address(alcx));
        gaugeFactory = new GaugeFactory();
        bribeFactory = new BribeFactory();
        voter = new Voter(address(veALCX), address(gaugeFactory), address(bribeFactory));

        alcx.approve(address(veALCX), 2e25);
        veALCX.createLock(TOKEN_1, 4 * 365 * 86400);

        distributor = new RewardsDistributor(address(veALCX));
        veALCX.setVoter(address(voter));

        InitializationParams memory params = InitializationParams(
            address(voter),
            address(veALCX),
            address(distributor),
            supply,
            rewards,
            stepdown
        );

        minter = new Minter(params);

        address[] memory tokens = new address[](1);
        tokens[0] = address(alcx);

        // Initialize after minter is created to set minter address
        voter.initialize(tokens, address(minter));

        distributor.setDepositor(address(minter));

        alcx.grantRole(keccak256("MINTER"), address(minter));

        voter.createGauge(address(alcx), Voter.GaugeType.Staking);
        voter.createGauge(alUSDPool, Voter.GaugeType.Staking);

        address gaugeAddress = voter.gauges(address(alcx));
        address gaugeAddress2 = voter.gauges(alUSDPool);

        gauge = StakingGauge(gaugeAddress);
        gauge2 = StakingGauge(gaugeAddress2);

        hevm.stopPrank();
    }

    function testEmergencyCouncilCanKillAndReviveGauges() public {
        hevm.startPrank(admin);

        address gaugeAddress = address(gauge);

        voter.killGauge(gaugeAddress);
        assertFalse(voter.isAlive(gaugeAddress));

        voter.reviveGauge(gaugeAddress);
        assertTrue(voter.isAlive(gaugeAddress));

        hevm.stopPrank();
    }

    function testFailCouncilCannotKillNonExistentGauge() public {
        hevm.startPrank(admin);

        voter.killGauge(address(0xDEAD));

        hevm.stopPrank();
    }

    function testFailNoOneElseCanKillGauges() public {
        hevm.prank(address(0xbeef));

        address gaugeAddress = address(gauge);

        voter.killGauge(gaugeAddress);

        // Gauge should still be alive
        assertTrue(voter.isAlive(gaugeAddress));

        hevm.stopPrank();
    }

    function testKilledGaugeCannotDeposit() public {
        hevm.startPrank(admin);

        address gaugeAddress = address(gauge);
        voter.killGauge(gaugeAddress);

        uint256 amount = alcx.balanceOf(admin);
        alcx.approve(gaugeAddress, amount);

        hevm.expectRevert(abi.encodePacked(""));

        gauge.deposit(amount, 1);

        hevm.stopPrank();
    }

    function testKilledGaugeCanWithdraw() public {
        hevm.startPrank(admin);

        address gaugeAddress = address(gauge);

        uint256 amount = alcx.balanceOf(admin);
        alcx.approve(gaugeAddress, amount);

        gauge.deposit(amount, 1);

        voter.killGauge(gaugeAddress);

        gauge.withdrawToken(amount, 1);

        hevm.stopPrank();
    }

    function testKilledGaugeCanUpdateButGoesToZero() public {
        hevm.startPrank(admin);

        hevm.warp(block.timestamp + 86400 * 7 * 2);
        hevm.roll(block.number + 1);

        minter.updatePeriod();
        voter.updateGauge(address(gauge));

        address[] memory gauges = new address[](1);
        gauges[0] = address(gauge);

        voter.killGauge(address(gauge));

        voter.updateFor(gauges);

        assertEq(voter.claimable(address(gauge)), 0);

        hevm.stopPrank();
    }

    function testKilledGaugeCanDistributeButGoesToZero() public {
        hevm.startPrank(admin);

        hevm.warp(block.timestamp + 86400 * 7 * 2);
        hevm.roll(block.number + 1);

        minter.updatePeriod();
        voter.updateGauge(address(gauge));

        address[] memory gauges = new address[](1);
        gauges[0] = address(gauge);

        voter.updateFor(gauges);

        voter.killGauge(address(gauge));

        assertEq(voter.claimable(address(gauge)), 0);

        hevm.stopPrank();
    }

    function testCanStillDistroAllWithKilledGauge() public {
        hevm.startPrank(admin);

        hevm.warp(block.timestamp + 86400 * 7 * 2);
        hevm.roll(block.number + 1);

        minter.updatePeriod();
        voter.updateGauge(address(gauge));
        voter.updateGauge(address(gauge2));

        address[] memory gauges = new address[](2);
        gauges[0] = address(gauge);
        gauges[1] = address(gauge2);

        voter.updateFor(gauges);

        voter.killGauge(address(gauge2));

        // Should be able to claim from gauge
        voter.distro();

        hevm.stopPrank();
    }
}
