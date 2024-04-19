// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract MinterTest is BaseTest {
    uint256 epochsUntilTail = 80;
    uint256 tokenId;

    function setUp() public {
        setupContracts(block.timestamp);

        tokenId = createVeAlcx(admin, TOKEN_1, MAXTIME, false);
    }

    // Test emissions for a single epoch
    function testEpochEmissions() external {
        uint256 treasuryBalanceBefore = alcx.balanceOf(address(devmsig));

        // Set the block timestamp to be the next epoch
        hevm.warp(newEpoch());

        uint256 currentTotalEmissions = minter.circulatingEmissionsSupply();
        uint256 epochEmissions = minter.epochEmission();

        assertEq(
            minter.calculateEmissions(epochEmissions, minter.veAlcxEmissionsRate()),
            (epochEmissions * minter.veAlcxEmissionsRate()) / minter.BPS(),
            "incorrect veALCX emissions"
        );
        assertEq(
            minter.calculateEmissions(epochEmissions, minter.timeEmissionsRate()),
            (epochEmissions * minter.timeEmissionsRate()) / minter.BPS(),
            "incorrect time emissions"
        );
        assertEq(
            minter.calculateEmissions(epochEmissions, minter.treasuryEmissionsRate()),
            (epochEmissions * minter.treasuryEmissionsRate()) / minter.BPS(),
            "incorrect treasury emissions"
        );

        // Mint emissions for epoch
        voter.distribute();

        uint256 distributorBalance = alcx.balanceOf(address(distributor));
        uint256 voterBalance = alcx.balanceOf(address(voter));
        uint256 timeBalance = alcx.balanceOf(address(timeGauge));
        uint256 treasuryBalance = (alcx.balanceOf(address(devmsig)) - treasuryBalanceBefore);

        uint256 totalAfterEpoch = minter.circulatingEmissionsSupply();
        emit log_named_uint("emissions after one epoch (ether)", totalAfterEpoch / TOKEN_1);

        assertEq(
            epochEmissions,
            voterBalance + distributorBalance + timeBalance + treasuryBalance,
            "incorrect emission distribution"
        );
        assertEq(totalAfterEpoch, currentTotalEmissions + epochEmissions);
    }

    // Test reaching emissions tail
    function testTailEmissions() external {
        // Mint emissions for the amount of epochs until tail emissions target
        hevm.warp(newEpoch());
        voter.distribute();

        for (uint8 i = 1; i <= epochsUntilTail; ++i) {
            hevm.warp(newEpoch());
            voter.distribute();
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

        // Rewards should equal the starting amount contract was initialized with
        assertEq(startingRewards, rewards);

        // After no epoch has passed, amount claimable should be 0
        assertEq(distributor.claimable(tokenId), 0);

        // Fast forward one epoch
        hevm.warp(newEpoch());
        hevm.roll(block.number + 1);

        voter.distribute();

        // After one epoch rewards amount should decrease by the defined stepdown amount
        assertEq(minter.stepdown(), startingRewards - minter.rewards());

        // Fast forward one epoch
        hevm.warp(newEpoch());
        hevm.roll(block.number + 1);

        voter.distribute();

        // After two epochs the amount of ALCX claimable for a veALCX token should increase
        assertGt(distributor.claimable(tokenId), 0);
    }

    // Claiming rewards early should result in a penalty that is returned to veALCX holders
    function testClaimRewardsEarly() public {
        initializeVotingEscrow();

        hevm.startPrank(admin);

        // Initial balance of accounts ALCX
        uint256 alcxBalanceBefore = alcx.balanceOf(admin);

        // After no epoch has passed, amount claimable should be 0
        assertEq(distributor.claimable(tokenId), 0, "amount claimable should be 0");

        // Fast forward one epoch
        hevm.warp(newEpoch());
        hevm.roll(block.number + 1);

        voter.distribute();

        // Initial ALCX balance of the rewards distributor
        uint256 distributorBalanceBefore = alcx.balanceOf(address(distributor));

        // Total amount of rewards claimable
        uint256 claimable = distributor.claimable(tokenId);

        // Claim ALCX rewards early without compounding
        uint256 amountClaimed = distributor.claim(tokenId, false);

        // Balance after claiming ALCX rewards
        uint256 alcxBalanceAfter = alcx.balanceOf(admin);

        // ALCX Balance of rewards distributor after receiving fee for claiming early
        uint256 distributorBalanceAfter = alcx.balanceOf(address(distributor));

        // Fee for claiming rewards early
        uint256 claimFee = ((claimable * veALCX.claimFeeBps()) / distributor.BPS());

        // Amount claimed should be the claimable amount minus fee
        assertEq(amountClaimed, claimable - claimFee, "incorrect amount claimed");

        // veALCX owner balance should increase by the amount claimed
        assertEq(alcxBalanceAfter - alcxBalanceBefore, amountClaimed, "unexpected account ALCX balance");

        // Rewards distributor ALCX balance should increase by the fee amount
        assertEq(
            distributorBalanceAfter,
            distributorBalanceBefore + claimFee - claimable,
            "unexpected distributor ALCX balance"
        );

        // Amount claimable should be reset after claiming
        assertEq(distributor.claimable(tokenId), 0, "amount claimable should be 0");
    }

    // Rewards require an epoch to pass before there is a claimable amount
    // Rewards are dependent on time in epoch in which veALCX was created
    function testRewardsWithinEpoch() public {
        initializeVotingEscrow();

        // Get a fresh epoch
        hevm.warp(newEpoch());
        voter.distribute();

        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        // Fast forward 1/2 epoch
        hevm.warp(block.timestamp + nextEpoch / 2);
        hevm.roll(block.number + 1);

        uint256 tokenId2 = createVeAlcx(beef, TOKEN_1, MAXTIME, false);

        // Finish the epoch
        hevm.warp(newEpoch());
        voter.distribute();

        // Go to the next epoch
        hevm.warp(newEpoch());
        voter.distribute();

        uint256 claimable1 = distributor.claimable(tokenId1);
        uint256 claimable2 = distributor.claimable(tokenId2);

        assertGt(claimable1, claimable2, "token with earlier deposit should have more claimable rewards");
    }

    // Compound claiming adds ALCX rewards into their exisiting veALCX position
    function testCompoundRewards() public {
        initializeVotingEscrow();

        hevm.startPrank(admin);

        // Initial amount of BPT locked in a veALCX position
        (uint256 initLockedAmount, , , ) = veALCX.locked(tokenId);

        // After no epoch has passed, amount claimable should be 0
        assertEq(distributor.claimable(tokenId), 0, "amount claimable should be 0");

        // Fast forward one epoch
        hevm.warp(newEpoch());
        hevm.roll(block.number + 1);

        voter.distribute();

        (uint256 amount, ) = distributor.amountToCompound(distributor.claimable(tokenId));

        // Accounts must provide proportional amount of WETH to deposit into the Balancer pool
        weth.approve(address(distributor), amount);
        uint256 wethBalanceBefore = weth.balanceOf(admin);

        // Claim ALCX rewards and compound into exisiting veALCX position with WETH
        distributor.claim(tokenId, true);

        uint256 wethBalanceAfter = weth.balanceOf(admin);

        // Updated amount of BPT locked
        (uint256 nextLockedAmount, , , ) = veALCX.locked(tokenId);

        // BPT locked should be higher after compounding
        assertGt(nextLockedAmount, initLockedAmount, "error compounding");

        // WETH balance should decrease by amount used to compound
        assertEq(wethBalanceBefore - wethBalanceAfter, amount);

        // Fast forward one epoch
        hevm.warp(newEpoch());
        hevm.roll(block.number + 1);

        voter.distribute();

        // Make sure account has enough eth to compound
        (amount, ) = distributor.amountToCompound(distributor.claimable(tokenId));
        hevm.deal(admin, amount);

        // Claim ALCX rewards by providing ETH
        distributor.claim{ value: amount }(tokenId, true);

        assertEq(distributor.claimable(tokenId), 0, "amount claimable should be 0");
    }

    // Compound claiming should revert if user doesn't provide enough weth
    function testCompoundRewardsFailure() public {
        initializeVotingEscrow();

        hevm.startPrank(admin);

        assertEq(distributor.claimable(tokenId), 0, "amount claimable should be 0");
        assertEq(distributor.claim(tokenId, true), 0, "amount claimed should be 0");

        // Fast forward one epoch
        hevm.warp(newEpoch());
        hevm.roll(block.number + 1);

        voter.distribute();

        // Set weth balance to 0
        weth.transfer(dead, weth.balanceOf(admin));

        hevm.expectRevert(abi.encodePacked("insufficient balance to compound"));
        distributor.claim(tokenId, true);

        hevm.stopPrank();

        hevm.expectRevert(abi.encodePacked("not approved"));
        distributor.claim(tokenId, true);
    }

    // Compound claiming should revert if user doesn't provide enough weth
    function testCompoundRewardsFailureETH() public {
        deal(admin, 100 ether);

        initializeVotingEscrow();

        hevm.startPrank(admin);

        assertEq(distributor.claimable(tokenId), 0, "amount claimable should be 0");
        assertEq(distributor.claim(tokenId, true), 0, "amount claimed should be 0");

        // Fast forward one epoch
        hevm.warp(newEpoch());
        hevm.roll(block.number + 1);

        voter.distribute();

        // Set weth balance to 0
        weth.transfer(dead, weth.balanceOf(admin));

        hevm.expectRevert(abi.encodePacked("insufficient balance to compound"));
        distributor.claim(tokenId, true);

        hevm.expectRevert(abi.encodePacked("Value must be 0 if not compounding"));
        distributor.claim{ value: 1 ether }(tokenId, false);

        distributor.claim{ value: 100 ether }(tokenId, true);
        assertGt(admin.balance, 0);
        assertGt(100 ether, admin.balance);
    }

    // Test admin controlled functions
    function testAdminFunctions() public {
        assertEq(minter.initializer(), address(0), "minter not initialized");

        hevm.expectRevert(abi.encodePacked("not initializer"));
        minter.initialize();

        hevm.prank(address(0));
        hevm.expectRevert(abi.encodePacked("already initialized"));
        minter.initialize();

        hevm.expectRevert(abi.encodePacked("not admin"));
        minter.setAdmin(devmsig);

        hevm.expectRevert(abi.encodePacked("not admin"));
        minter.setVeAlcxEmissionsRate(1000);

        hevm.expectRevert(abi.encodePacked("not voter"));
        minter.updatePeriod();

        hevm.prank(admin);
        minter.setAdmin(devmsig);

        hevm.expectRevert(abi.encodePacked("not pending admin"));
        minter.acceptAdmin();

        hevm.startPrank(devmsig);

        minter.acceptAdmin();

        hevm.expectRevert(abi.encodePacked("cannot be greater than 100%"));
        minter.setVeAlcxEmissionsRate(10_000 * 2);

        minter.setVeAlcxEmissionsRate(1000);

        hevm.stopPrank();
    }

    function testSetTreasury() public {
        hevm.expectRevert(abi.encodePacked("not admin"));
        minter.setTreasury(beef);

        hevm.prank(admin);
        hevm.expectRevert(abi.encodePacked("treasury cannot be 0x0"));
        minter.setTreasury(address(0));

        hevm.prank(admin);
        minter.setTreasury(beef);
    }
}
