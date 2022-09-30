// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract VotingTest is BaseTest {
    Voter voter;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    RewardsDistributor distributor;
    Minter minter;

    uint256 depositAmount = 999 ether;
    uint256 lockTime = 30 days;

    function setUp() public {
        mintAlcx(admin, TOKEN_1);
        veALCX.setVoter(admin);

        hevm.startPrank(admin);

        ManaToken(MANA).setMinter(address(veALCX));

        gaugeFactory = new GaugeFactory();
        bribeFactory = new BribeFactory();
        voter = new Voter(address(veALCX), address(gaugeFactory), address(bribeFactory), address(MANA));

        address[] memory tokens = new address[](1);
        tokens[0] = address(alcx);
        voter.initialize(tokens, admin);

        alcx.approve(address(veALCX), TOKEN_1);
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

        distributor.setDepositor(address(minter));

        alcx.grantRole(keccak256("MINTER"), address(minter));

        voter.createGauge(alETHPool, Voter.GaugeType.Staking);

        hevm.roll(block.number + 1);
        assertGt(veALCX.balanceOfNFT(1), 995063075414519385);
        assertEq(alcx.balanceOf(address(veALCX)), TOKEN_1);

        minter.initialize();

        assertEq(veALCX.ownerOf(1), admin);

        hevm.roll(block.number + 1);

        // TODO once we determine how to distribute rewards, add tests
        // to check veALCX holder ALCX balances increasing over an epoch
        uint256 before = alcx.balanceOf(address(minter));
        assertEq(before, 0);

        hevm.warp(block.timestamp + 86400 * 14);
        hevm.roll(block.number + 1);

        minter.updatePeriod();
        assertGt(alcx.balanceOf(address(distributor)), before);
        assertGt(alcx.balanceOf(address(voter)), before);
        hevm.stopPrank();
    }

    function testSameEpochVoteOrReset() public {
        hevm.startPrank(admin);

        uint256 period = minter.activePeriod();

        // Move forward a week relative to period
        hevm.warp(period + 1 weeks);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;
        voter.vote(1, pools, weights, 0);

        // Move forward half epoch relative to period
        hevm.warp(period + 1 weeks / 2);

        // Voting again fails
        pools[0] = alUSDPool;
        hevm.expectRevert(abi.encodePacked("TOKEN_ALREADY_VOTED_THIS_EPOCH"));
        voter.vote(1, pools, weights, 0);

        // Resetting fails
        hevm.expectRevert(abi.encodePacked("TOKEN_ALREADY_VOTED_THIS_EPOCH"));
        voter.reset(1);

        hevm.stopPrank();
    }

    function testNextEpochVoteOrReset() public {
        hevm.startPrank(admin);

        hevm.warp(block.timestamp + 1 weeks);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        voter.vote(1, pools, weights, 0);

        // Next epoch
        hevm.warp(block.timestamp + 1 weeks);

        // New vote succeeds
        pools[0] = alUSDPool;
        voter.vote(1, pools, weights, 0);

        // Next epoch
        hevm.warp(block.timestamp + 1 weeks);

        // Resetting succeeds
        voter.reset(1);

        hevm.stopPrank();
    }

    // Test that a user accrues unclaimed MANA every epoch relative to their voting power
    function testManaAccrual() public {
        hevm.startPrank(admin);

        uint256 unclaimedBalance = veALCX.unclaimedManaBalance(1);
        uint256 claimableMana1 = veALCX.claimableMana(1);

        assertEq(unclaimedBalance, 0);

        voter.reset(1);

        uint256 accruedBalance = veALCX.unclaimedManaBalance(1);

        assertEq(accruedBalance, unclaimedBalance + claimableMana1);

        // Next epoch
        hevm.warp(block.timestamp + 1 weeks);

        uint256 claimableMana2 = veALCX.claimableMana(1);

        // Amount of MANA claimable per epoch decreases with voting power
        assertGt(claimableMana1, claimableMana2);

        voter.reset(1);

        accruedBalance = veALCX.unclaimedManaBalance(1);

        // Amount of unclaimed MANA increases per epoch
        assertEq(accruedBalance, unclaimedBalance + claimableMana1 + claimableMana2);

        hevm.stopPrank();
    }

    // veALCX holders should be able to claim their unclaimed mana
    function testClaimMana() public {
        hevm.startPrank(admin);

        uint256 claimedBalance = MANA.balanceOf(admin);

        assertEq(claimedBalance, 0);

        voter.reset(1);

        veALCX.claimMana(1, veALCX.unclaimedManaBalance(1));

        uint256 unclaimedBalance = veALCX.unclaimedManaBalance(1);
        claimedBalance = MANA.balanceOf(admin);

        // Unclaimed balance is 0 after claiming entire unclaimed balance
        assertEq(unclaimedBalance, 0);

        // Claimed balance is equal to the amount able to be claimed
        assertEq(claimedBalance, veALCX.claimableMana(1));

        hevm.stopPrank();
    }

    // veALCX holders should not be able to claim more than their unclaimed balance
    function testClaimManaLimit() public {
        hevm.startPrank(admin);

        uint256 claimedBalance = MANA.balanceOf(admin);
        uint256 unclaimedBalance = veALCX.unclaimedManaBalance(1);

        assertEq(claimedBalance, 0);
        assertEq(unclaimedBalance, 0);

        voter.reset(1);

        unclaimedBalance = veALCX.unclaimedManaBalance(1);

        veALCX.claimMana(1, unclaimedBalance / 2);

        claimedBalance = MANA.balanceOf(admin);

        assertEq(claimedBalance, unclaimedBalance / 2);

        hevm.expectRevert(abi.encodePacked("amount greater than unclaimed balance"));
        veALCX.claimMana(1, unclaimedBalance);

        hevm.stopPrank();
    }

    // veALCX holders can boost their vote with unclaimed MANA
    function testBoostVoteWithMana() public {
        hevm.startPrank(admin);

        hevm.warp(block.timestamp + 1 weeks);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        uint256 claimableMana1 = veALCX.claimableMana(1);

        // Vote without boost
        voter.vote(1, pools, weights, 0);

        // Get weight used without boosting with MANA
        uint256 usedWeight = voter.getUsedWeights(1);

        // Next epoch
        hevm.warp(block.timestamp + 1 weeks);

        uint256 unclaimedBalanceBefore = veALCX.unclaimedManaBalance(1);

        uint256 claimableMana2 = veALCX.claimableMana(1);

        // Vote with boost
        voter.vote(1, pools, weights, unclaimedBalanceBefore / 2);

        // Get weight used when boosting with MANA
        uint256 usedWeightBoosted = voter.getUsedWeights(1);
        uint256 unclaimedBalanceAfter = veALCX.unclaimedManaBalance(1);
        uint256 twoEpochsOfMana = claimableMana1 + claimableMana2;

        // Used weight should be greater when boosting with unused MANA
        assertGt(usedWeightBoosted, usedWeight);

        // Unclaimed balance should be less than two epochs worth of MANA due to boosting a vote
        assertLt(unclaimedBalanceAfter, twoEpochsOfMana);

        hevm.stopPrank();
    }

    // Votes cannot be boosted unless veALCX holder has an unclaimed MANA balance
    function testCannotBoostVote() public {
        hevm.startPrank(admin);

        hevm.warp(block.timestamp + 1 weeks);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        // Vote with insufficient boost
        hevm.expectRevert(abi.encodePacked("insufficient unclaimed MANA balance"));
        voter.vote(1, pools, weights, 100);

        voter.reset(1);

        // Next epoch
        hevm.warp(block.timestamp + 1 weeks);

        uint256 unclaimedManaBalance = veALCX.unclaimedManaBalance(1);

        assertGt(unclaimedManaBalance, 0);

        // Vote with insufficient boost
        hevm.expectRevert(abi.encodePacked("insufficient unclaimed MANA balance"));
        voter.vote(1, pools, weights, unclaimedManaBalance + 1);

        hevm.stopPrank();
    }
}
