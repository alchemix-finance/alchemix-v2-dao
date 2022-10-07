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
        veALCX.createLock(TOKEN_1, 4 * 365 * 86400, false);

        uint256 maxVotingPower = getMaxVotingPower(TOKEN_1, veALCX.lockEnd(1));

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

        assertEq(veALCX.balanceOfNFT(1), maxVotingPower);
        assertEq(alcx.balanceOf(address(veALCX)), TOKEN_1);

        minter.initialize();

        assertEq(veALCX.ownerOf(1), admin);

        hevm.roll(block.number + 1);

        // TODO once we determine how to distribute emissions, add tests
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

    // veALCX holders should be able to claim their unclaimed mana
    function testClaimMana() public {
        hevm.startPrank(admin);

        uint256 claimedBalance = MANA.balanceOf(admin);

        assertEq(claimedBalance, 0);

        voter.reset(1);

        claimedBalance = MANA.balanceOf(admin);

        // Claimed balance is equal to the amount able to be claimed
        assertEq(claimedBalance, veALCX.claimableMana(1));

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

        uint256 claimableMana = veALCX.claimableMana(1);
        uint256 votingWeight = veALCX.balanceOfNFT(1);

        // Vote with half of claimable MANA
        voter.vote(1, pools, weights, claimableMana / 2);

        // Get weight used from boosting with MANA
        uint256 usedWeight = voter.usedWeights(1);

        // Used weight should be greater when boosting with unused MANA
        assertGt(usedWeight, votingWeight);

        uint256 manaBalance = MANA.balanceOf(admin);
        // MANA balance should be remainaing MANA not used to boost
        assertEq(manaBalance, claimableMana / 2);

        hevm.stopPrank();
    }

    // Votes cannot be boosted with insufficient claimable MANA balance
    function testCannotBoostVote() public {
        hevm.startPrank(admin);

        hevm.warp(block.timestamp + 1 weeks);

        address[] memory pools = new address[](1);
        pools[0] = alETHPool;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        uint256 claimableMana = veALCX.claimableMana(1);

        // Vote with insufficient claimable MANA balance
        hevm.expectRevert(abi.encodePacked("insufficient claimable MANA balance"));
        voter.vote(1, pools, weights, claimableMana + 1);

        hevm.stopPrank();
    }

    // veALCX holder with max lock enabled should have constant max voting power
    function testMaxLockVotingPower() public {
        mintAlcx(account, TOKEN_1);

        hevm.startPrank(account);

        alcx.approve(address(veALCX), TOKEN_1);
        veALCX.createLock(TOKEN_1, 0, true);

        uint256 maxVotingPower = getMaxVotingPower(TOKEN_1, veALCX.lockEnd(2));

        uint256 votingPower1 = veALCX.balanceOfNFT(2);

        assertEq(votingPower1, maxVotingPower);

        hevm.warp(block.timestamp + 52 weeks);

        minter.updatePeriod();

        uint256 votingPower2 = veALCX.balanceOfNFT(2);

        // Voting power should remain the same with max lock enabled
        assertEq(votingPower1, votingPower2);

        // Disable max lock
        veALCX.updateUnlockTime(2, 0, false);

        hevm.warp(block.timestamp + 52 weeks);

        uint256 votingPower3 = veALCX.balanceOfNFT(2);

        // Disabling max lock should start the voting power decay
        assertLt(votingPower3, votingPower2);

        hevm.stopPrank();
    }
}
