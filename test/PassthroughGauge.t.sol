// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract PassthroughGauge is BaseTest {
    Voter voter;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    RewardsDistributor distributor;
    Minter minter;
    CurveGauge curveGauge;

    uint256 nextEpoch = 86400 * 14;
    bytes32 public proposal = 0xd7db40d1ca142cb5ca24bce5d0f78f3b037fde6c7ebb3c3650a317e910278b1f;

    function setUp() public {
        setupBaseTest();

        // Setup specific time to test snapshot period
        // https://snapshot.org/#/cvx.eth/proposal/0xd7db40d1ca142cb5ca24bce5d0f78f3b037fde6c7ebb3c3650a317e910278b1f
        hevm.warp(15920279 - 3 weeks);

        veALCX.setVoter(admin);

        hevm.startPrank(admin);

        ManaToken(MANA).setMinter(address(veALCX));

        gaugeFactory = new GaugeFactory();
        bribeFactory = new BribeFactory();
        voter = new Voter(address(veALCX), address(gaugeFactory), address(bribeFactory), address(MANA));

        IERC20(bpt).approve(address(veALCX), 2e25);
        veALCX.createLock(TOKEN_1, 365 days, false);

        distributor = new RewardsDistributor(address(veALCX), address(weth), address(balancerVault), priceFeed);
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

        minter.initialize();

        voter.createGauge(address(votium), Voter.GaugeType.Passthrough);

        address gaugeAddress = voter.gauges(address(votium));

        curveGauge = CurveGauge(gaugeAddress);

        hevm.stopPrank();
    }

    function testPassthroughRewards() public {
        hevm.startPrank(admin);

        uint256 period = minter.activePeriod();
        hevm.warp(period);

        uint256 votiumBalanceBefore = alcx.balanceOf(votium);

        address[] memory pools = new address[](1);
        pools[0] = address(votium);
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        // Move forward epoch
        hevm.warp(period + 1 weeks);

        voter.vote(1, pools, weights, 0);

        voter.distribute(address(curveGauge));

        uint256 gaugeBalance = alcx.balanceOf(address(curveGauge));

        // Set time to be Nov 11th to test valid proposal
        hevm.warp(15948915);

        curveGauge.passthroughRewards(gaugeBalance, keccak256(abi.encodePacked(proposal)));

        uint256 votiumBalanceAfter = alcx.balanceOf(votium);

        hevm.stopPrank();
    }
}
