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

    function setUp() public {
        setupBaseTest();

        veALCX.setVoter(admin);

        hevm.startPrank(admin);

        ManaToken(MANA).setMinter(address(veALCX));

        gaugeFactory = new GaugeFactory();
        bribeFactory = new BribeFactory();
        voter = new Voter(address(veALCX), address(gaugeFactory), address(bribeFactory), address(MANA));

        address[] memory tokens = new address[](1);
        tokens[0] = address(alcx);
        voter.initialize(tokens, admin);

        veALCX.createLock(TOKEN_1, MAXTIME, false);

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

        distributor.setDepositor(address(minter));

        alcx.grantRole(keccak256("MINTER"), address(minter));

        voter.createGauge(alETHPool, Voter.GaugeType.Staking, uint256(0));

        hevm.roll(block.number + 1);

        uint256 maxVotingPower = getMaxVotingPower(TOKEN_1, veALCX.lockEnd(1));

        assertEq(veALCX.balanceOfToken(1), maxVotingPower);
        assertEq(IERC20(bpt).balanceOf(address(veALCX)), TOKEN_1);

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
        address[] memory claimants = new address[](1);
        claimants[0] = admin;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = TOKEN_1;

        hevm.startPrank(admin);

        IERC20(bpt).approve(address(veALCX), TOKEN_1);

        for (uint256 i = 0; i < claimants.length; i++) {
            veALCX.createLockFor(amounts[i], MAXTIME, false, claimants[i]);
        }

        assertEq(veALCX.ownerOf(2), admin);
        assertEq(veALCX.ownerOf(3), address(0));

        hevm.roll(block.number + 1);

        hevm.stopPrank();
    }

    // Verify the setup paramaters and emissions schedule are working as expected
    function testWeeklyEmissionsSchedule() public {
        initializeVotingEscrow();

        uint256 startingRewards = minter.rewards();

        minter.updatePeriod();

        // Rewards should equal the starting amount contract was initialized with
        assertEq(startingRewards, rewards);

        // After no epoch has passed, amount claimable should be 0
        assertEq(distributor.claimable(1), 0);

        // Fast forward one epoch
        hevm.warp(block.timestamp + nextEpoch);
        hevm.roll(block.number + 1);

        minter.updatePeriod();

        // After one epoch rewards amount should decrease by the defined stepdown amount
        assertEq(minter.stepdown(), startingRewards - minter.rewards());

        // Fast forward one epoch
        hevm.warp(block.timestamp + nextEpoch);
        hevm.roll(block.number + 1);

        minter.updatePeriod();

        // After two epochs the amount of ALCX claimable for a veALCX token should increase
        assertGt(distributor.claimable(1), 0);
    }

    // Claiming rewards early should result in a penalty
    function testClaimRewardsEarly() public {
        initializeVotingEscrow();

        hevm.startPrank(admin);

        // Initial balance of accounts ALCX
        uint256 alcxBalanceBefore = alcx.balanceOf(admin);

        minter.updatePeriod();

        // After no epoch has passed, amount claimable should be 0
        assertEq(distributor.claimable(1), 0, "amount claimable should be 0");

        // Fast forward one epoch
        hevm.warp(block.timestamp + nextEpoch);
        hevm.roll(block.number + 1);

        minter.updatePeriod();

        // Amount claimable
        uint256 claimable = distributor.claimable(1);

        // Claim ALCX rewards early without compounding
        uint256 amountClaimed = distributor.claim(1, false);

        // Balance after claiming ALCX rewards
        uint256 alcxBalanceAfter = alcx.balanceOf(admin);

        // Amount claimed should be the claimable amount minus fee
        assertEq(
            amountClaimed,
            claimable - ((claimable * veALCX.claimFeeBps()) / distributor.BPS()),
            "incorrect amount claimed"
        );

        // Accounts ALCX balance should increase by the amount claimed
        assertEq(alcxBalanceAfter - alcxBalanceBefore, amountClaimed, "unexpected ALCX balance");

        // Amount claimable should be reset after claiming
        assertEq(distributor.claimable(1), 0, "amount claimable should be 0");
    }

    // Users can add ALCX rewards into their exisiting veALCX position
    function testCompoundRewards() public {
        initializeVotingEscrow();

        hevm.startPrank(admin);

        // Initial amount of BPT locked in a veALCX position
        (int256 initLockedAmount, , , ) = veALCX.locked(1);

        minter.updatePeriod();

        // After no epoch has passed, amount claimable should be 0
        assertEq(distributor.claimable(1), 0, "amount claimable should be 0");

        // Fast forward one epoch
        hevm.warp(block.timestamp + nextEpoch);
        hevm.roll(block.number + 1);

        minter.updatePeriod();

        (uint256 amount, ) = distributor.amountToCompound(distributor.claimable(1));

        // Accounts must provide proportional amount of WETH to deposit into the Balancer pool
        weth.approve(address(distributor), amount);
        uint256 wethBalanceBefore = weth.balanceOf(admin);

        // Claim ALCX rewards and compound into exisiting veALCX position with WETH
        distributor.claim(1, true);

        uint256 wethBalanceAfter = weth.balanceOf(admin);

        // Updated amount of BPT locked
        (int256 nextLockedAmount, , , ) = veALCX.locked(1);

        // BPT locked should be higher after compounding
        assertGt(nextLockedAmount, initLockedAmount, "error compounding");

        // WETH balance should decrease by amount used to compound
        assertEq(wethBalanceBefore - wethBalanceAfter, amount);

        // Fast forward one epoch
        hevm.warp(block.timestamp + nextEpoch);
        hevm.roll(block.number + 1);

        minter.updatePeriod();

        (amount, ) = distributor.amountToCompound(distributor.claimable(1));
        hevm.deal(admin, amount);

        // Claim ALCX rewards by providing ETH
        distributor.claim{ value: amount }(1, true);

        assertEq(distributor.claimable(1), 0, "amount claimable should be 0");
    }

    function testCompoundRewardsFailure() public {
        initializeVotingEscrow();

        hevm.startPrank(admin);

        minter.updatePeriod();

        // After no epoch has passed, amount claimable should be 0
        hevm.expectRevert(abi.encodePacked("nothing to claim"));
        distributor.claim(1, true);
        assertEq(distributor.claimable(1), 0, "amount claimable should be 0");

        // Fast forward one epoch
        hevm.warp(block.timestamp + nextEpoch);
        hevm.roll(block.number + 1);

        minter.updatePeriod();

        // Set weth balance to 0
        weth.transfer(address(0xdead), weth.balanceOf(admin));

        // Compound claiming should revert if user doesn't provide enough weth
        hevm.expectRevert(abi.encodePacked("insufficient eth to compound"));
        distributor.claim(1, true);
    }
}
