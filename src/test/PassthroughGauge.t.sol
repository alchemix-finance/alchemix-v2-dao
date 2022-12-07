// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract PassthroughGaugeTest is BaseTest {
    Voter voter;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    RewardsDistributor distributor;
    Minter minter;
    CurveGauge alUsdGauge;
    CurveGauge alEthGauge;
    CurveGauge alUsdFraxBpGauge;
    PassthroughGauge sushiGauge;

    uint256 nextEpoch = 86400 * 14;
    uint256 snapshotWeek = 15948915;

    uint256 platformFee = 400; // 4%
    uint256 DENOMINATOR = 10000; // denominates weights 10000 = 100%

    // Proposal id from snapshot url
    // https://snapshot.org/#/cvx.eth/proposal/0xd7db40d1ca142cb5ca24bce5d0f78f3b037fde6c7ebb3c3650a317e910278b1f
    bytes32 public proposal = 0xd7db40d1ca142cb5ca24bce5d0f78f3b037fde6c7ebb3c3650a317e910278b1f;

    // Votium contract that is sent rewards
    address votiumReceiver = 0x19BBC3463Dd8d07f55438014b021Fb457EBD4595;

    // Votium contract that receives rewards (via the receiver)
    address votiumStash = 0x378Ba9B73309bE80BF4C2c027aAD799766a7ED5A;

    // Pool addresses
    address alUsdPoolAddress = 0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c;
    address alEthPoolAddress = 0xC4C319E2D4d66CcA4464C0c2B32c9Bd23ebe784e;
    address alUsdFraxBpPoolAddress = 0xB30dA2376F63De30b42dC055C93fa474F31330A5;
    address sushiPoolAddress = 0x7519C93fC5073E15d89131fD38118D73A72370F8;

    // Votium pool indexes
    uint256 alUsdIndex = 34;
    uint256 alEthIndex = 46;
    uint256 alUsdFraxBpIndex = 105;

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

        // Create votium gauges
        voter.createGauge(alUsdPoolAddress, Voter.GaugeType.Curve, alUsdIndex, votiumReceiver);
        voter.createGauge(alEthPoolAddress, Voter.GaugeType.Curve, alEthIndex, votiumReceiver);
        voter.createGauge(alUsdFraxBpPoolAddress, Voter.GaugeType.Curve, alUsdFraxBpIndex, votiumReceiver);

        // Create sushi gauge
        voter.createGauge(sushiPoolAddress, Voter.GaugeType.Passthrough, uint256(0), zeroAddress);

        // Get address of new gauges
        address alUsdGaugeAddress = voter.gauges(alUsdPoolAddress);
        address alEthGaugeAddress = voter.gauges(alEthPoolAddress);
        address alUsdFraxBpGaugeAddress = voter.gauges(alUsdFraxBpPoolAddress);
        address sushiGaugeAddress = voter.gauges(sushiPoolAddress);

        alUsdGauge = CurveGauge(alUsdGaugeAddress);
        alEthGauge = CurveGauge(alEthGaugeAddress);
        alUsdFraxBpGauge = CurveGauge(alUsdFraxBpGaugeAddress);
        sushiGauge = PassthroughGauge(sushiGaugeAddress);

        hevm.stopPrank();
    }

    // Rewards should be passed through to votium and sushi pools
    function testPassthroughGaugeRewards() public {
        hevm.startPrank(admin);

        uint256 period = minter.activePeriod();
        hevm.warp(period);

        uint256 votiumBalanceBefore = alcx.balanceOf(votiumStash);
        uint256 sushiBalanceBefore = alcx.balanceOf(sushiPoolAddress);

        address[] memory pools = new address[](4);
        pools[0] = alUsdPoolAddress;
        pools[1] = alEthPoolAddress;
        pools[2] = alUsdFraxBpPoolAddress;
        pools[3] = sushiPoolAddress;
        uint256[] memory weights = new uint256[](4);
        weights[0] = 5000;
        weights[1] = 5000;
        weights[2] = 5000;
        weights[3] = 5000;

        // Move forward epoch
        hevm.warp(period + 1 weeks);

        voter.vote(1, pools, weights, 0);

        address[] memory gauges = new address[](4);
        gauges[0] = address(alUsdGauge);
        gauges[1] = address(alEthGauge);
        gauges[2] = address(alUsdFraxBpGauge);
        gauges[3] = address(sushiGauge);

        // Set time to be a week of a snapshot vote to test a valid proposal
        hevm.warp(snapshotWeek);

        // Update gauges to get claimable rewards value
        minter.updatePeriod();
        voter.updateFor(gauges);

        // Claimable rewards of each gauge
        uint256 sushiGaugeClaimable = voter.claimable(address(sushiGauge));
        uint256 alUsdGaugeClaimable = voter.claimable(address(alUsdGauge));
        uint256 alEthGaugeClaimable = voter.claimable(address(alEthGauge));
        uint256 alUsdFraxBpGaugeClaimable = voter.claimable(address(alUsdFraxBpGauge));

        voter.distribute(gauges, proposal);

        uint256 sushiBalanceAfter = alcx.balanceOf(sushiPoolAddress);

        uint256 votiumBalanceAfter = alcx.balanceOf(votiumStash);

        uint256 votiumClaimable = alUsdGaugeClaimable + alEthGaugeClaimable + alUsdFraxBpGaugeClaimable;

        uint256 votiumFee = (votiumClaimable * platformFee) / DENOMINATOR;

        // Votium stash ALCX balance should increase by the three curve pools claimable amount minus votium fee
        assertEq(votiumBalanceAfter - votiumBalanceBefore, votiumClaimable - votiumFee);

        // Sushi pool ALCX balance should increase by the claimable amount
        assertEq(sushiBalanceAfter - sushiBalanceBefore, sushiGaugeClaimable);

        hevm.stopPrank();
    }
}
