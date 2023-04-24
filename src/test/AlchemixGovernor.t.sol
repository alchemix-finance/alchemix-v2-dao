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

        assertEq(governor.timelock(), address(timelockExecutor));
    }

    function testExecutorCanCreateGaugesForAnyAddress(address a) public {
        hevm.assume(a != address(0));

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

    function testFailCannotProposeWithoutSufficientBalance() public {
        // propose
        hevm.startPrank(dead);
        address[] memory targets = new address[](1);
        targets[0] = address(voter);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(voter.whitelist.selector, usdc);
        string memory description = "Whitelist USDC";

        governor.propose(targets, values, calldatas, description, MAINNET);
        hevm.stopPrank();
    }

    function testProposalsNeedsQuorumToPass() public {
        createVeAlcx(dead, 1, MAXTIME, false);

        assertFalse(voter.isWhitelisted(usdc));

        address[] memory targets = new address[](1);
        targets[0] = address(voter);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(voter.whitelist.selector, usdc);
        string memory description = "Whitelist USDC";

        // proposal should fail to meet threshold when veALCX amount is too low
        hevm.startPrank(dead);
        hevm.expectRevert(abi.encodePacked("Governor: proposer votes below proposal threshold"));
        governor.propose(targets, values, calldatas, description, MAINNET);

        uint256 proposalThreshold = governor.proposalThreshold();
        uint256 votes = governor.getVotes(dead, block.timestamp);

        assertGt(proposalThreshold, votes);

        hevm.stopPrank();

        // propose
        hevm.startPrank(admin);

        hevm.warp(block.timestamp + 2 days); // delay

        uint256 pid = governor.propose(targets, values, calldatas, description, MAINNET);
        hevm.warp(block.timestamp + 2 days); // delay
        hevm.stopPrank();

        // vote
        hevm.startPrank(beef);
        governor.castVote(pid, 1);
        hevm.warp(block.timestamp + 1 weeks); // voting period
        hevm.stopPrank();

        // execute
        hevm.startPrank(admin);
        // Proposal unsuccessful due to _quorumReached returning false
        hevm.expectRevert(abi.encodePacked("Governor: proposal not successful"));
        governor.execute(targets, values, calldatas, keccak256(bytes(description)), MAINNET);

        hevm.stopPrank();
    }

    function testProposalHasQuorum() public {
        assertFalse(voter.isWhitelisted(usdc));

        address[] memory targets = new address[](1);
        targets[0] = address(voter);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(voter.whitelist.selector, usdc);
        string memory description = "Whitelist USDC";

        hevm.warp(block.timestamp + 2 days); // delay

        // propose
        hevm.startPrank(admin);
        uint256 pid = governor.propose(targets, values, calldatas, description, MAINNET);
        hevm.warp(block.timestamp + 2 days); // delay
        hevm.stopPrank();

        // vote
        hevm.startPrank(admin);
        governor.castVote(pid, 1);
        hevm.warp(block.timestamp + 1 weeks); // voting period
        hevm.stopPrank();

        // execute
        hevm.startPrank(admin);
        governor.execute(targets, values, calldatas, keccak256(bytes(description)), MAINNET);
        hevm.stopPrank();

        assertTrue(voter.isWhitelisted(usdc));
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
        governor.setProposalNumerator(60);

        governor.setProposalNumerator(50);

        assertEq(governor.proposalNumerator(), 50);

        hevm.stopPrank();
    }

    function testProposalThresholdMetBeforeProposalBlock() public {
        uint256 proposalThreshold = governor.proposalThreshold();

        createVeAlcx(dead, proposalThreshold, MAXTIME, false);

        assertFalse(voter.isWhitelisted(usdc));

        address[] memory targets = new address[](1);
        targets[0] = address(voter);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(voter.whitelist.selector, usdc);
        string memory description = "Whitelist USDC";

        // proposal should fail to meet threshold when veALCX amount is too low
        hevm.startPrank(dead);

        hevm.expectRevert(abi.encodePacked("Governor: proposer votes below proposal threshold"));
        governor.propose(targets, values, calldatas, description, MAINNET);

        hevm.warp(block.timestamp + 12);
        governor.propose(targets, values, calldatas, description, MAINNET);

        uint256 votes = governor.getVotes(dead, block.timestamp);

        assertLt(proposalThreshold, votes);

        hevm.stopPrank();
    }
}
