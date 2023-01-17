// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract AlchemixGovernorTest is BaseTest {
    StakingGauge gauge;
    Bribe bribe;
    TimelockExecutor timelockExecutor;
    AlchemixGovernor governor;

    function setUp() public {
        setupBaseTest(block.timestamp);

        hevm.startPrank(admin);

        IERC20(bpt).transfer(address(0xbeef), TOKEN_1);
        IERC20(bpt).transfer(address(0xdead), TOKEN_1);

        veALCX.createLock(90 * TOKEN_1, 365 days, false);
        hevm.roll(block.number + 1);

        hevm.stopPrank();

        // Create veALCX for 0xbeef
        hevm.startPrank(address(0xbeef));

        IERC20(bpt).approve(address(veALCX), TOKEN_1);
        veALCX.createLock(TOKEN_1, 365 days, false);
        hevm.roll(block.number + 1);

        hevm.stopPrank();

        hevm.startPrank(admin);

        alcx.approve(address(gaugeFactory), 15 * TOKEN_100K);
        voter.createGauge(alETHPool, IVoter.GaugeType.Staking);
        address gaugeAddress = voter.gauges(alETHPool);
        address bribeAddress = voter.bribes(gaugeAddress);
        gauge = StakingGauge(gaugeAddress);
        bribe = Bribe(bribeAddress);

        timelockExecutor = new TimelockExecutor(1 days);
        governor = new AlchemixGovernor(veALCX, TimelockExecutor(timelockExecutor));

        timelockExecutor.setAdmin(address(governor));
        voter.setExecutor(address(timelockExecutor));

        hevm.stopPrank();

        hevm.prank(address(governor));
        timelockExecutor.acceptAdmin();

        hevm.prank(address(timelockExecutor));
        voter.acceptExecutor();
    }

    function testExecutorCanCreateGaugesForAnyAddress(address a) public {
        hevm.assume(a != address(0));

        hevm.startPrank(address(timelockExecutor));
        voter.createGauge(a, IVoter.GaugeType.Staking);
        hevm.stopPrank();
    }

    function testVeAlcxMergesAutoDelegates() public {
        // 0xbeef + 0xdead > quorum
        hevm.startPrank(address(0xdead));

        IERC20(bpt).approve(address(veALCX), TOKEN_1 / 3);
        veALCX.createLock(TOKEN_1 / 3, 365 days, false);

        hevm.roll(block.number + 1);

        uint256 pre2 = veALCX.getVotes(address(0xbeef));
        uint256 pre3 = veALCX.getVotes(address(0xdead));

        // merge
        veALCX.approve(address(0xbeef), 3);
        veALCX.transferFrom(address(0xdead), address(0xbeef), 3);

        hevm.stopPrank();

        hevm.startPrank(address(0xbeef));

        veALCX.merge(3, 2);

        hevm.stopPrank();

        // assert vote balances
        uint256 post2 = veALCX.getVotes(address(0xbeef));

        assertApproxEq(
            pre2 + pre3,
            post2,
            365 days // merge rounds down time lock
        );
    }

    function testFailCannotProposeWithoutSufficientBalance() public {
        // propose
        hevm.startPrank(address(0xdead));
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
        hevm.startPrank(address(0xbeef));
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
