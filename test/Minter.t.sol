// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract MinterTest is BaseTest {
    Voter voter;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    RewardsDistributor distributor;
    Minter minter;

    uint256 nextEpoch = 86400 * 14;
    uint256 epochsUntilTail = 80;
    uint256 internal constant LOCK = 86400 * 7 * 52 * 4;

    function setUp() public {
        mintAlcx(admin, 1e25);
        veALCX.setVoter(admin);

        hevm.startPrank(admin);

        ManaToken(MANA).setMinter(address(veALCX));

        gaugeFactory = new GaugeFactory();
        bribeFactory = new BribeFactory();
        voter = new Voter(address(veALCX), address(gaugeFactory), address(bribeFactory), address(MANA));

        address[] memory tokens = new address[](1);
        tokens[0] = address(alcx);
        voter.initialize(tokens, admin);

        alcx.approve(address(veALCX), 2e25);
        veALCX.createLock(TOKEN_1, 4 * 365 * 86400, false);

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

        voter.createGauge(alETHPool, Voter.GaugeType.Staking);

        hevm.roll(block.number + 1);

        uint256 maxVotingPower = getMaxVotingPower(TOKEN_1, veALCX.lockEnd(1));

        assertEq(veALCX.balanceOfNFT(1), maxVotingPower);
        assertEq(alcx.balanceOf(address(veALCX)), TOKEN_1);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;
        voter.vote(1, pools, weights, 0);

        minter.initialize();

        hevm.stopPrank();
    }

    // Test emissions for a single epoch
    function testEpochEmissions() external {
        // Set the block timestamp to be the next epoch
        hevm.warp(block.timestamp + nextEpoch);

        uint256 currentTotalEmissions = minter.circulatingEmissionsSupply();
        uint256 epochEmissions = minter.epochEmission();

        // Mint emissions for epoch
        minter.updatePeriod();

        uint256 distributorBalance = alcx.balanceOf(address(distributor));
        uint256 voterBalance = alcx.balanceOf(address(voter));

        uint256 totalAfterEpoch = minter.circulatingEmissionsSupply();
        emit log_named_uint("emissions after one epoch (ether)", totalAfterEpoch / TOKEN_1);

        assertEq(epochEmissions, voterBalance + distributorBalance);
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
        emit log_named_uint("tail emissions supply (ether)", tailEmissionSupply / TOKEN_1);

        // Assert rewards are the constant tail emissions value
        assertEq(tailRewards, minter.TAIL_EMISSIONS_RATE());

        // Assert stepdown is 0 once tail emissions are reached
        assertEq(tailStepdown, 0);

        // Assert total emissions are the approximate target at the tail
        assertApproxEq(tailEmissionSupply, supplyAtTail, 17e18);
    }

    function initializeVotingEscrow() public {
        mintAlcx(admin, TOKEN_1M);

        address[] memory claimants = new address[](1);
        claimants[0] = admin;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = TOKEN_1M;

        hevm.startPrank(admin);

        for (uint256 i = 0; i < claimants.length; i++) {
            veALCX.createLockFor(amounts[i], LOCK, false, claimants[i]);
        }

        assertEq(veALCX.ownerOf(2), admin);
        assertEq(veALCX.ownerOf(3), address(0));
        hevm.roll(block.number + 1);

        hevm.stopPrank();
    }

    function testMinterWeeklyDistribute() public {
        initializeVotingEscrow();

        uint256 startingRewards = minter.rewards();

        minter.updatePeriod();

        assertEq(startingRewards, rewards);
        assertEq(distributor.claimable(1), 0);

        hevm.warp(block.timestamp + nextEpoch);
        hevm.roll(block.number + 1);

        minter.updatePeriod();

        assertEq(minter.stepdown(), startingRewards - minter.rewards());

        hevm.warp(block.timestamp + nextEpoch);
        hevm.roll(block.number + 1);

        minter.updatePeriod();

        assertGt(distributor.claimable(1), 3013259951171);

        distributor.claim(1);
        assertEq(distributor.claimable(1), 0);

        hevm.warp(block.timestamp + nextEpoch);
        hevm.roll(block.number + 1);

        minter.updatePeriod();

        distributor.claim(1);

        hevm.warp(block.timestamp + nextEpoch);
        hevm.roll(block.number + 1);

        minter.updatePeriod();

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;

        distributor.claimMany(tokenIds);

        hevm.warp(block.timestamp + nextEpoch);
        hevm.roll(block.number + 1);

        minter.updatePeriod();

        distributor.claim(1);

        hevm.warp(block.timestamp + nextEpoch);
        hevm.roll(block.number + 1);

        minter.updatePeriod();

        distributor.claimMany(tokenIds);

        assertEq(distributor.claimable(1), 0);
        assertEq(distributor.claimable(2), 0);

        hevm.warp(block.timestamp + nextEpoch);
        hevm.roll(block.number + 1);

        minter.updatePeriod();

        distributor.claim(1);
    }
}
