// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "../../lib/openzeppelin-contracts/contracts/governance/Governor.sol";

/// @title IL2Governor
/// @author Alchemix Finance
abstract contract IL2Governor is IGovernor {
	/**
	 * @dev Emitted when a proposal is created.
	 */
	event ProposalCreated(
		uint256 proposalId,
		address proposer,
		address[] targets,
		uint256[] values,
		string[] signatures,
		bytes[] calldatas,
		uint256 startBlock,
		uint256 endBlock,
		string description,
		uint256 chainId
	);

	/**
	 * @notice module:core
	 * @dev Hashing function used to (re)build the proposal id from the proposal details..
	 */
	function hashProposal(
		address[] memory targets,
		uint256[] memory values,
		bytes[] memory calldatas,
		bytes32 descriptionHash,
		uint256 chainId
	) public pure virtual returns (uint256);

	/**
	 * @dev Create a new proposal. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
	 * {IGovernor-votingPeriod} blocks after the voting starts.
	 *
	 * Emits a {ProposalCreated} event.
	 */
	function propose(
		address[] memory targets,
		uint256[] memory values,
		bytes[] memory calldatas,
		string memory description,
		uint256 chainId
	) public virtual returns (uint256 proposalId);

	/**
	 * @dev Execute a successful proposal. This requires the quorum to be reached, the vote to be successful, and the
	 * deadline to be reached.
	 *
	 * Emits a {ProposalExecuted} event.
	 *
	 * Note: some module can modify the requirements for execution, for example by adding an additional timelock.
	 */
	function execute(
		address[] memory targets,
		uint256[] memory values,
		bytes[] memory calldatas,
		bytes32 descriptionHash,
		uint256 chainId
	) public payable virtual returns (uint256 proposalId);
}
