// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract PassthroughGaugeTest is BaseTest {
    uint256 nextEpoch = 2 weeks;
    uint256 snapshotWeek = 15948915;

    uint256 platformFee = 400; // 4%
    uint256 DENOMINATOR = 10000; // denominates weights 10000 = 100%

    // Proposal id from snapshot url
    // https://snapshot.org/#/cvx.eth/proposal/0xd7db40d1ca142cb5ca24bce5d0f78f3b037fde6c7ebb3c3650a317e910278b1f
    bytes32 public proposal = 0xd7db40d1ca142cb5ca24bce5d0f78f3b037fde6c7ebb3c3650a317e910278b1f;

    // Votium contract that receives rewards (via the receiver)
    address votiumStash = 0x378Ba9B73309bE80BF4C2c027aAD799766a7ED5A;

    function setUp() public {
        setupBaseTest(snapshotWeek - 3 weeks);
    }

    // Rewards should be passed through to votium and sushi pools
    function testPassthroughGaugeRewards() public {
        hevm.startPrank(admin);

        IERC20(bpt).approve(address(veALCX), 2e25);
        veALCX.createLock(TOKEN_1, MAXTIME, false);

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

        alUsdGauge.updateProposal(proposal);
        alEthGauge.updateProposal(proposal);
        alUsdFraxBpGauge.updateProposal(proposal);

        voter.distribute(gauges);

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
