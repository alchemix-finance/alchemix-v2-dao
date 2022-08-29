// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract MinterTest is BaseTest {
    VotingEscrow veALCX;
    Voter voter;
    PairFactory pairFactory;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    RewardsDistributor distributor;
    Minter minter;

    uint256 nextEpoch = 86400 * 14;
    uint256 epochsUntilTail = 80;

    function setUp() public {
        hevm.startPrank(admin);

        veALCX = new VotingEscrow(address(alcx));
        pairFactory = new PairFactory();
        gaugeFactory = new GaugeFactory();
        bribeFactory = new BribeFactory();
        voter = new Voter(address(veALCX), address(gaugeFactory), address(bribeFactory), address(pairFactory));

        address[] memory tokens = new address[](1);
        tokens[0] = address(alcx);
        voter.initialize(tokens, admin);

        alcx.approve(address(veALCX), 1e18);
        veALCX.createLock(1e18, 4 * 365 * 86400);

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

        distributor.setDepositor(address(minter));

        alcx.grantRole(keccak256("MINTER"), address(minter));

        voter.createGauge(address(alETHPool));

        hevm.roll(block.number + 1);
        assertGt(veALCX.balanceOfNFT(1), 995063075414519385);
        assertEq(alcx.balanceOf(address(veALCX)), 1e18);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;
        voter.vote(1, pools, weights);

        // Initialize minter
        minter.initialize();
    }

    // Test emissions for a single epoch
    function testEpochEmissions() external {
        // Set the block timestamp to be the next epoch
        hevm.warp(block.timestamp + nextEpoch);

        uint256 currentTotalEmissions = minter.circulatingEmissionsSupply();
        uint256 epochEmissions = minter.epochEmission();

        // Mint emissions for epoch
        minter.updatePeriod();

        uint256 totalAfterEpoch = minter.circulatingEmissionsSupply();
        emit log_named_uint("emissions after one epoch (ether)", totalAfterEpoch / 1e18);

        assertEq(totalAfterEpoch, currentTotalEmissions + epochEmissions);
    }

    // Test reaching emissions tail
    function testTailEmissions() external {
        // Mint emissions for the amount of epochs until tail emissions target
        for (uint8 i = 0; i <= epochsUntilTail; ++i) {
            hevm.warp(block.timestamp + nextEpoch);
            minter.updatePeriod();
        }

        uint256 tailRewards = minter.rewards();
        uint256 tailStepdown = minter.stepdown();
        uint256 tailEmissionSupply = minter.circulatingEmissionsSupply();
        emit log_named_uint("tail emissions supply (ether)", tailEmissionSupply / 1e18);

        // Assert rewards are the constant tail emissions value
        assertEq(tailRewards, minter.TAIL_EMISSIONS_RATE());

        // Assert stepdown is 0 once tail emissions are reached
        assertEq(tailStepdown, 0);

        // Assert total emissions are the approximate target at the tail
        assertApproxEq(tailEmissionSupply, supplyAtTail, 17e18);
    }
}
