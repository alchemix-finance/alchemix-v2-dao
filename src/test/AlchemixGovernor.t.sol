// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract AlchemixGovernorTest is BaseTest {
    function setUp() public {
        setupBaseTest(block.timestamp);

        deal(bpt, beef, TOKEN_1);
        deal(bpt, dead, TOKEN_1);

        // Create veALCX for admin
        hevm.startPrank(admin);

        veALCX.createLock(90 * TOKEN_1, MAXTIME, false);
        hevm.roll(block.number + 1);

        hevm.stopPrank();

        // Create veALCX for 0xbeef
        hevm.startPrank(beef);

        IERC20(bpt).approve(address(veALCX), TOKEN_1);
        veALCX.createLock(TOKEN_1, MAXTIME, false);
        hevm.roll(block.number + 1);

        hevm.stopPrank();
    }

    function testExecutorCanCreateGaugesForAnyAddress(address a) public {
        hevm.assume(a != address(0));

        hevm.startPrank(address(timelockExecutor));
        voter.createGauge(a, IVoter.GaugeType.Staking);
        hevm.stopPrank();
    }

    function testVeAlcxMergesAutoDelegates() public {
        // 0xbeef + 0xdead > quorum
        hevm.startPrank(dead);

        IERC20(bpt).approve(address(veALCX), TOKEN_1 / 3);
        veALCX.createLock(TOKEN_1 / 3, MAXTIME, false);

        hevm.roll(block.number + 1);

        uint256 pre2 = veALCX.getVotes(beef);
        uint256 pre3 = veALCX.getVotes(dead);

        // merge
        veALCX.approve(beef, 3);
        veALCX.transferFrom(dead, beef, 3);

        hevm.stopPrank();

        hevm.startPrank(beef);

        veALCX.merge(3, 2);

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
        calldatas[0] = abi.encodeWithSelector(voter.whitelist.selector, address(USDC));
        string memory description = "Whitelist USDC";

        governor.propose(targets, values, calldatas, description, MAINNET);
        hevm.stopPrank();
    }

    function testProposalsNeedsQuorumToPass() public {
        assertFalse(voter.isWhitelisted(address(USDC)));

        address[] memory targets = new address[](1);
        targets[0] = address(voter);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(voter.whitelist.selector, address(USDC));
        string memory description = "Whitelist USDC";

        // propose
        hevm.startPrank(admin);
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
        assertFalse(voter.isWhitelisted(address(USDC)));

        address[] memory targets = new address[](1);
        targets[0] = address(voter);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(voter.whitelist.selector, address(USDC));
        string memory description = "Whitelist USDC";

        // propose
        hevm.startPrank(admin);
        uint256 pid = governor.propose(targets, values, calldatas, description, MAINNET);
        hevm.warp(block.timestamp + 2 days); // delay
        hevm.roll(block.number + 1);
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

        assertTrue(voter.isWhitelisted(address(USDC)));
    }
}
