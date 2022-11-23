// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract CurveGaugeTest is BaseTest {
    Voter voter;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    RewardsDistributor distributor;
    Minter minter;
    CurveGauge alUsdGauge;
    CurveGauge alEthGauge;
    CurveGauge alUsdFraxBpGauge;

    uint256 nextEpoch = 86400 * 14;
    uint256 snapshotWeek = 15948915;

    uint256 platformFee = 400; // 4%
    uint256 DENOMINATOR = 10000; // denominates weights 10000 = 100%

    // Proposal taken from snapshot url
    // https://snapshot.org/#/cvx.eth/proposal/0xd7db40d1ca142cb5ca24bce5d0f78f3b037fde6c7ebb3c3650a317e910278b1f
    bytes32 public proposal = 0xd7db40d1ca142cb5ca24bce5d0f78f3b037fde6c7ebb3c3650a317e910278b1f;

    // Contract that receives votium bribes
    address votiumStash = 0x378Ba9B73309bE80BF4C2c027aAD799766a7ED5A;

    address alUsdPoolAddress = 0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c;
    address alEthPoolAddress = 0xC4C319E2D4d66CcA4464C0c2B32c9Bd23ebe784e;
    address alUsdFraxBpPoolAddress = 0xB30dA2376F63De30b42dC055C93fa474F31330A5;

    uint256 alUsdPool = 34;
    uint256 alEthPool = 46;
    uint256 alUsdFraxBpPool = 105;

    function setUp() public {
        setupBaseTest();

        // Setup specific time to test snapshot period
        hevm.warp(snapshotWeek - 3 weeks);

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

        voter.createGauge(alUsdPoolAddress, Voter.GaugeType.Curve, alUsdPool);
        voter.createGauge(alEthPoolAddress, Voter.GaugeType.Curve, alEthPool);
        voter.createGauge(alUsdFraxBpPoolAddress, Voter.GaugeType.Curve, alUsdFraxBpPool);

        address alUsdGaugeAddress = voter.gauges(alUsdPoolAddress);
        address alEthGaugeAddress = voter.gauges(alEthPoolAddress);
        address alUsdFraxBpGaugeAddress = voter.gauges(alUsdFraxBpPoolAddress);

        alUsdGauge = CurveGauge(alUsdGaugeAddress);
        alEthGauge = CurveGauge(alEthGaugeAddress);
        alUsdFraxBpGauge = CurveGauge(alUsdFraxBpGaugeAddress);

        hevm.stopPrank();
    }

    function testCurveAlUsdRewards() public {
        hevm.startPrank(admin);

        uint256 period = minter.activePeriod();
        hevm.warp(period);

        uint256 votiumBalanceBefore = alcx.balanceOf(votiumStash);

        address[] memory pools = new address[](3);
        pools[0] = alUsdPoolAddress;
        pools[1] = alEthPoolAddress;
        pools[2] = alUsdFraxBpPoolAddress;
        uint256[] memory weights = new uint256[](3);
        weights[0] = 5000;
        weights[1] = 5000;
        weights[2] = 5000;

        // Move forward epoch
        hevm.warp(period + 1 weeks);

        voter.vote(1, pools, weights, 0);

        address[] memory gauges = new address[](3);
        gauges[0] = address(alUsdGauge);
        gauges[1] = address(alEthGauge);
        gauges[2] = address(alUsdFraxBpGauge);

        voter.distribute(gauges);

        uint256 alUsdGaugeBalance = alcx.balanceOf(address(alUsdGauge));
        uint256 alEthGaugeBalance = alcx.balanceOf(address(alEthGauge));
        uint256 alUsdFraxBpGaugeBalance = alcx.balanceOf(address(alUsdFraxBpGauge));

        uint256 totalBalances = alUsdGaugeBalance + alEthGaugeBalance + alUsdFraxBpGaugeBalance;

        // Set time to be a week of a snapshot vote to test a valid proposal
        hevm.warp(snapshotWeek);

        alUsdGauge.passthroughRewards(alUsdGaugeBalance, proposal);
        alEthGauge.passthroughRewards(alEthGaugeBalance, proposal);
        alUsdFraxBpGauge.passthroughRewards(alUsdFraxBpGaugeBalance, proposal);

        uint256 votiumBalanceAfter = alcx.balanceOf(votiumStash);

        uint256 votiumFee = (totalBalances * platformFee) / DENOMINATOR;

        assertEq(votiumBalanceAfter - votiumBalanceBefore, totalBalances - votiumFee);

        hevm.stopPrank();
    }
}
