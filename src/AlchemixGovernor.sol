// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IGovernor } from "openzeppelin-contracts/contracts/governance/IGovernor.sol";
import { IVotes } from "openzeppelin-contracts/contracts/governance/utils/IVotes.sol";

import { L2Governor } from "src/governance/L2Governor.sol";
import { L2GovernorCountingSimple } from "src/governance/L2GovernorCountingSimple.sol";
import { L2GovernorVotes } from "src/governance/L2GovernorVotes.sol";
import { L2GovernorVotesQuorumFraction } from "src/governance/L2GovernorVotesQuorumFraction.sol";

import "src/governance/TimelockExecutor.sol";

contract AlchemixGovernor is L2Governor, L2GovernorVotes, L2GovernorVotesQuorumFraction, L2GovernorCountingSimple {
    address public admin;
    uint256 public constant MAX_PROPOSAL_NUMERATOR = 50; // max 5%
    uint256 public constant PROPOSAL_DENOMINATOR = 1000;
    uint256 public proposalNumerator = 2; // start at 0.02%

    constructor(IVotes _ve, TimelockExecutor timelockAddress)
        L2Governor("Alchemix Governor", timelockAddress)
        L2GovernorVotes(_ve)
        L2GovernorVotesQuorumFraction(4) // 4%
    {
        admin = msg.sender;
    }

    function setAdmin(address newAdmin) external {
        require(msg.sender == admin, "not admin");
        admin = newAdmin;
    }

    function setProposalNumerator(uint256 numerator) external {
        require(msg.sender == admin, "not admin");
        require(numerator <= MAX_PROPOSAL_NUMERATOR, "numerator too high");
        proposalNumerator = numerator;
    }

    function proposalThreshold() public view override(L2Governor) returns (uint256) {
        return (token.getPastTotalSupply(block.timestamp) * proposalNumerator) / PROPOSAL_DENOMINATOR;
    }
}
