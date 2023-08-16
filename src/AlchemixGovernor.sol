// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "src/governance/L2GovernorCountingSimple.sol";
import "src/governance/L2GovernorVotes.sol";
import "src/governance/L2GovernorVotesQuorumFraction.sol";
import "src/governance/TimelockExecutor.sol";
import "openzeppelin-contracts/contracts/governance/IGovernor.sol";
import "openzeppelin-contracts/contracts/governance/utils/IVotes.sol";

/**
 * @title Alchemix Governor
 * @notice Alchemix specific governance parameters
 * @dev Extends the Open Zeppelin governance system
 */
contract AlchemixGovernor is L2Governor, L2GovernorVotes, L2GovernorVotesQuorumFraction, L2GovernorCountingSimple {
    address public admin;
    address public pendingAdmin;
    uint256 public constant MAX_PROPOSAL_NUMERATOR = 500; // 5%
    uint256 public constant PROPOSAL_DENOMINATOR = 10000; // BPS denominator
    uint256 public proposalNumerator = 400; // 4%

    constructor(
        IVotes _ve,
        TimelockExecutor timelockAddress
    )
        L2Governor("Alchemix Governor", timelockAddress)
        L2GovernorVotes(_ve)
        L2GovernorVotesQuorumFraction(4) // quorum is 4% of total supply
    {
        require(address(_ve) != address(0), "ve address cannot be zero address");
        require(address(timelockAddress) != address(0), "timelock address cannot be zero address");

        admin = msg.sender;
    }

    /*
        View functions
    */

    /**
     * @dev Part of the Governor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_.
     */
    function proposalThreshold() public view override(L2Governor) returns (uint256) {
        return (token.getPastTotalSupply(block.timestamp) * proposalNumerator) / PROPOSAL_DENOMINATOR;
    }

    /*
        Admin functions
    */

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "not admin");
        pendingAdmin = _admin;
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "not pending admin");
        admin = pendingAdmin;
        emit AdminUpdated(pendingAdmin);
    }

    function setProposalNumerator(uint256 numerator) external {
        require(msg.sender == admin, "not admin");
        require(numerator <= MAX_PROPOSAL_NUMERATOR, "numerator too high");
        proposalNumerator = numerator;
        emit ProposalNumberSet(numerator);
    }

    function setVotingDelay(uint256 newDelay) external {
        require(msg.sender == admin, "not admin");
        votingDelay = newDelay;
        emit VotingDelaySet(votingDelay);
    }

    function setVotingPeriod(uint256 newPeriod) external {
        require(msg.sender == admin, "not admin");
        votingPeriod = newPeriod;
        emit VotingPeriodSet(votingPeriod);
    }
}
