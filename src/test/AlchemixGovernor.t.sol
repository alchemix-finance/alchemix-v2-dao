// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract AlchemixGovernorTest is BaseTest {
    uint256 tokenId1;
    uint256 tokenId2;
    uint256 tokenId3;

    function setUp() public {
        setupContracts(block.timestamp);

        // Create veALCX for admin
        tokenId1 = createVeAlcx(admin, TOKEN_100K, MAXTIME, false);

        // Create veALCX for 0xbeef
        tokenId2 = createVeAlcx(beef, TOKEN_1, MAXTIME, false);

        // Can't propose and vote in the same block as a veALCX is created
        hevm.warp(block.timestamp + 1);

        assertEq(governor.timelock(), address(timelockExecutor));
    }

    function craftTestProposal()
        internal
        view
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description)
    {
        targets = new address[](1);
        targets[0] = address(voter);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(voter.whitelist.selector, usdc);
        description = "Whitelist USDC";
    }

    function testExecutorCanCreateGaugesForAnyAddress(address a) public {
        hevm.assume(a != address(0));
        hevm.assume(voter.gauges(a) == address(0));

        hevm.startPrank(address(timelockExecutor));
        voter.createGauge(a, IVoter.GaugeType.Passthrough);
        hevm.stopPrank();
    }

    function testVeAlcxMergesAutoDelegates() public {
        tokenId3 = createVeAlcx(dead, TOKEN_1 / 3, MAXTIME, false);

        uint256 pre2 = veALCX.getVotes(beef);
        uint256 pre3 = veALCX.getVotes(dead);

        hevm.startPrank(dead);

        // merge
        veALCX.approve(beef, tokenId3);
        veALCX.transferFrom(dead, beef, tokenId3);

        hevm.stopPrank();

        hevm.startPrank(beef);

        veALCX.merge(tokenId3, tokenId2);

        hevm.stopPrank();

        // assert vote balances
        uint256 post2 = veALCX.getVotes(beef);

        assertApproxEq(
            pre2 + pre3,
            post2,
            MAXTIME // merge rounds down time lock
        );
    }

    function testProposeFail() public {
        createVeAlcx(admin, TOKEN_100K, MAXTIME, false);
        createVeAlcx(beef, 1e18, MAXTIME, false);

        hevm.startPrank(beef);
        (address[] memory t, uint256[] memory v, bytes[] memory c, string memory d) = craftTestProposal();

        hevm.expectRevert(abi.encodePacked("Governor: veALCX power below proposal threshold"));
        governor.propose(t, v, c, d, MAINNET);

        hevm.stopPrank();
    }

    function testPropose() public {
        createVeAlcx(admin, TOKEN_100K, MAXTIME, false);
        createVeAlcx(beef, 1e18, MAXTIME, false);

        hevm.startPrank(admin);

        uint256 adminVotes = governor.getVotes(admin, block.timestamp - 1);
        uint256 pastVotes = veALCX.getPastVotes(admin, block.timestamp - 1);
        assertEq(adminVotes, pastVotes, "governor and veALCX calculated different votes");

        (address[] memory t, uint256[] memory v, bytes[] memory c, string memory d) = craftTestProposal();
        governor.propose(t, v, c, d, MAINNET);

        hevm.stopPrank();
    }

    function testProposalExecutionTimestamp() public {
        (address[] memory t, uint256[] memory v, bytes[] memory c, string memory d) = craftTestProposal();
        hevm.startPrank(admin);
        governor.propose(t, v, c, d, MAINNET);
        uint256 delay = governor.votingDelay() + governor.votingPeriod() + timelockExecutor.executionDelay();
        bytes32 opId = timelockExecutor.hashOperationBatch(t, v, c, 0, keccak256(bytes(d)), MAINNET);
        assertEq(timelockExecutor.getTimestamp(opId), block.timestamp + delay);
    }

    function testProposalNeedsQuorumToPass() public {
        createVeAlcx(dead, TOKEN_1, MAXTIME, false);
        createVeAlcx(admin, TOKEN_100K, MAXTIME, false);

        assertFalse(voter.isWhitelisted(usdc));

        (address[] memory t, uint256[] memory v, bytes[] memory c, string memory d) = craftTestProposal();

        uint256 votingPower = veALCX.getVotes(dead);
        uint256 quorum = governor.quorum(block.timestamp);

        assertGt(quorum, votingPower, "quorum should be greater than voting power");

        // proposal should fail to meet threshold when veALCX amount is too low
        hevm.startPrank(dead);
        hevm.expectRevert(abi.encodePacked("Governor: veALCX power below proposal threshold"));
        governor.propose(t, v, c, d, MAINNET);

        uint256 proposalThreshold = governor.proposalThreshold();
        uint256 votes = governor.getVotes(dead, block.timestamp);

        assertGt(proposalThreshold, votes);

        hevm.stopPrank();

        // propose
        hevm.startPrank(admin);
        uint256 pid = governor.propose(t, v, c, d, MAINNET);
        hevm.warp(block.timestamp + governor.votingDelay() + 1); // delay
        hevm.stopPrank();

        // vote
        hevm.startPrank(beef);
        governor.castVote(pid, 1);
        hevm.warp(block.timestamp + governor.votingPeriod() + 1); // voting period
        hevm.stopPrank();

        // execute
        hevm.startPrank(admin);
        // Proposal unsuccessful due to _quorumReached returning false
        hevm.expectRevert(abi.encodePacked("Governor: proposal not successful"));
        governor.execute(t, v, c, keccak256(bytes(d)), MAINNET);

        hevm.stopPrank();
    }

    function testProposalHasQuorum() public {
        assertFalse(voter.isWhitelisted(usdc));

        (address[] memory t, uint256[] memory v, bytes[] memory c, string memory d) = craftTestProposal();

        hevm.warp(block.timestamp + 2 days); // delay

        uint256 quorum = governor.quorum(block.timestamp);
        uint256 votingPower = veALCX.getVotes(admin);

        assertGt(votingPower, quorum, "voting power should be greater than quorum");

        // propose
        hevm.startPrank(admin);
        uint256 pid = governor.propose(t, v, c, d, MAINNET);
        hevm.warp(block.timestamp + governor.votingDelay() + 1); // voting delay
        hevm.roll(block.number + 1);
        hevm.stopPrank();

        // vote
        hevm.startPrank(admin);
        governor.castVote(pid, 1);
        hevm.warp(block.timestamp + governor.votingPeriod() + 1); // voting period
        hevm.stopPrank();

        // execute
        hevm.startPrank(admin);
        hevm.warp(block.timestamp + timelockExecutor.executionDelay() + 1); // execution delay
        governor.execute(t, v, c, keccak256(bytes(d)), MAINNET);
        hevm.stopPrank();

        assertTrue(voter.isWhitelisted(usdc));
    }

    function testOnlyExecutorCanExecute() public {
        assertFalse(voter.isWhitelisted(usdc));

        (address[] memory t, uint256[] memory v, bytes[] memory c, string memory d) = craftTestProposal();

        hevm.warp(block.timestamp + 2 days); // delay

        // propose
        hevm.startPrank(admin);
        uint256 pid = governor.propose(t, v, c, d, MAINNET);
        hevm.warp(block.timestamp + governor.votingDelay() + 1); // voting delay
        hevm.roll(block.number + 1);
        hevm.stopPrank();

        // vote
        hevm.startPrank(admin);
        governor.castVote(pid, 1);
        hevm.warp(block.timestamp + governor.votingPeriod() + 1); // voting period
        hevm.stopPrank();

        // execute
        hevm.startPrank(admin);
        hevm.warp(block.timestamp + timelockExecutor.executionDelay() + 1); // execution delay
        hevm.expectRevert(
            abi.encodePacked(
                "AccessControl: account 0x8392f6669292fa56123f71949b52d883ae57e225 is missing role 0xd8aa0f3194971a2a116679f7c2090f6939c8d4e01a2a8d7e41d55e5351469e63"
            )
        );
        timelockExecutor.executeBatch(t, v, c, "", keccak256(bytes(d)), MAINNET);
    }

    // Only admin can set a new proposal numerator (up to a max)
    function testUpdateProposalNumerator() public {
        hevm.prank(admin);
        governor.setAdmin(devmsig);

        hevm.startPrank(devmsig);

        hevm.expectRevert(abi.encodePacked("not admin"));
        governor.setProposalNumerator(60);

        governor.acceptAdmin();

        hevm.expectRevert(abi.encodePacked("numerator too high"));
        governor.setProposalNumerator(6000);

        governor.setProposalNumerator(500);

        assertEq(governor.proposalNumerator(), 500);

        hevm.stopPrank();
    }

    function testProposalThresholdMetBeforeProposalBlock() public {
        uint256 proposalThreshold = governor.proposalThreshold();

        createVeAlcx(dead, proposalThreshold, MAXTIME, false);

        assertFalse(voter.isWhitelisted(usdc));

        (address[] memory t, uint256[] memory v, bytes[] memory c, string memory d) = craftTestProposal();

        // proposal should fail to meet threshold when veALCX amount is too low
        hevm.startPrank(dead);

        hevm.expectRevert(abi.encodePacked("Governor: veALCX power below proposal threshold"));
        governor.propose(t, v, c, d, MAINNET);

        hevm.warp(block.timestamp + 12);
        governor.propose(t, v, c, d, MAINNET);

        uint256 votes = governor.getVotes(dead, block.timestamp);

        assertLt(proposalThreshold, votes);

        hevm.stopPrank();
    }

    function testSetVotingDelay() public {
        uint256 initialDelay = governor.votingDelay();

        hevm.prank(admin);

        governor.setVotingDelay(initialDelay + 1 days);

        (address[] memory t, uint256[] memory v, bytes[] memory c, string memory d) = craftTestProposal();

        hevm.startPrank(admin);

        uint256 pid = governor.propose(t, v, c, d, MAINNET);

        hevm.warp(block.timestamp + initialDelay + 1);
        hevm.roll(block.number + 1);

        hevm.expectRevert(abi.encodePacked("Governor: vote not currently active"));
        governor.castVote(pid, 1);

        hevm.warp(block.timestamp + 1 days);
        hevm.roll(block.number + 1);

        governor.castVote(pid, 1);

        hevm.stopPrank();
    }

    function testSetVotingPeriod() public {
        uint256 initialPeriod = governor.votingPeriod();

        hevm.prank(admin);

        governor.setVotingPeriod(initialPeriod + 1 days);

        (address[] memory t, uint256[] memory v, bytes[] memory c, string memory d) = craftTestProposal();

        hevm.startPrank(admin);

        uint256 pid = governor.propose(t, v, c, d, MAINNET);

        hevm.warp(block.timestamp + governor.votingDelay() + 1);
        hevm.roll(block.number + 1);

        governor.castVote(pid, 1);

        hevm.warp(block.timestamp + initialPeriod + 1);
        hevm.roll(block.number + 1);

        uint256 state = uint256(governor.state(pid));
        assertEq(state, uint256(IGovernor.ProposalState.Active));

        hevm.warp(block.timestamp + 1 days);
        hevm.roll(block.number + 1);

        state = uint256(governor.state(pid));
        assertEq(state, uint256(IGovernor.ProposalState.Succeeded));

        hevm.stopPrank();
    }

    function testTimelockSchedulerRoleSchedule() public {
        (address[] memory t, uint256[] memory v, bytes[] memory c, string memory d) = craftTestProposal();
        hevm.prank(beef);
        timelockExecutor.schedule(t[0], v[0], c[0], 0, keccak256(bytes(d)), MAINNET, timelockExecutor.executionDelay());
    }

    function testTimelockSchedulerRoleScheduleBatch() public {
        (address[] memory t, uint256[] memory v, bytes[] memory c, string memory d) = craftTestProposal();
        hevm.prank(beef);
        timelockExecutor.scheduleBatch(t, v, c, 0, keccak256(bytes(d)), MAINNET, timelockExecutor.executionDelay());
    }

    function testCancellerRole() public {
        assertFalse(voter.isWhitelisted(usdc));

        (address[] memory t, uint256[] memory v, bytes[] memory c, string memory d) = craftTestProposal();

        hevm.warp(block.timestamp + 2 days); // delay

        // propose
        hevm.startPrank(admin);
        uint256 pid = governor.propose(t, v, c, d, MAINNET);
        hevm.warp(block.timestamp + governor.votingDelay() + 1); // voting delay
        hevm.roll(block.number + 1);
        hevm.stopPrank();

        // vote
        hevm.startPrank(admin);
        governor.castVote(pid, 1);
        hevm.warp(block.timestamp + governor.votingPeriod() + 1); // voting period
        hevm.stopPrank();

        // is scheduled
        assertEq(uint256(governor.state(pid)), uint256(IGovernor.ProposalState.Succeeded));

        // cancel
        bytes32 id = timelockExecutor.hashOperationBatch(t, v, c, 0, keccak256(bytes(d)), MAINNET);
        hevm.prank(admin);
        timelockExecutor.cancel(id);

        // execute
        hevm.startPrank(admin);
        hevm.warp(block.timestamp + timelockExecutor.executionDelay() + 1); // execution delay
        hevm.expectRevert(abi.encodePacked("TimelockExecutor: operation is not ready"));
        governor.execute(t, v, c, keccak256(bytes(d)), MAINNET);
        hevm.stopPrank();

        assertFalse(voter.isWhitelisted(usdc));
    }
}
