// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "src/BaseGauge.sol";
import "src/interfaces/IBribe.sol";
import "src/interfaces/IVoter.sol";
import "src/interfaces/IVotingEscrow.sol";
import "src/interfaces/votium/IVotiumBribe.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Curve Gauge
 * @notice Gauge to handle distribution of rewards to a given Curve pool via Votium
 * @dev Pool index is subject to change and proposal id is located in the snapshot url
 */
contract CurveGauge is BaseGauge {
    using SafeERC20 for IERC20;

    // Votium pool index (subject to change)
    uint256 poolIndex;

    // Proposal id from snapshot url
    bytes32 proposal;

    // Flag to determine if proposal has been updated
    bool proposalUpdated;

    // Flag to determine if gauge has been setup with necessary variables
    bool initialized;

    event ProposalUpdated(bytes32 indexed newProposal, bool proposalUpdated);
    event IndexUpdated(uint256 indexed newIndex);
    event Initialized(uint256 poolIndex, address receiver, bool initialized);

    constructor(
        address _bribe,
        address _ve,
        address _voter
    ) {
        bribe = _bribe;
        ve = _ve;
        voter = _voter;

        admin = IVoter(voter).executor();

        IBribe(bribe).setGauge(address(this));
        rewardToken = IVotingEscrow(ve).ALCX();
        IBribe(bribe).addRewardToken(rewardToken);
        isReward[rewardToken] = true;
        rewards.push(rewardToken);
    }

    /*
        External functions
    */

    /**
     * @notice Initialize curve gauge specific variables
     * @param _poolIndex Index of pool on votium
     * @param _receiver Votium contract that is sent rewards
     */
    function initialize(uint256 _poolIndex, address _receiver) external {
        require(msg.sender == admin, "not admin");
        receiver = _receiver;
        poolIndex = _poolIndex;
        initialized = true;

        emit Initialized(poolIndex, receiver, initialized);
    }

    /**
     * @notice Update the pool index
     * @param _poolIndex New pool index
     * @dev Pool index on votium subject to change
     */
    function updateIndex(uint256 _poolIndex) external {
        require(msg.sender == admin, "not admin");
        poolIndex = _poolIndex;

        emit IndexUpdated(poolIndex);
    }

    /**
     * @notice Set the proposal id
     * @param _proposal Proposal id from snapshot url
     * @dev Proposal id must be set manually every epoch
     */
    function updateProposal(bytes32 _proposal) external {
        require(msg.sender == admin, "not admin");
        proposal = _proposal;
        proposalUpdated = true;

        emit ProposalUpdated(proposal, proposalUpdated);
    }

    /*
        Internal functions
    */

    /**
     * @notice Pass rewards to votium contract
     * @param _amount Amount of rewards
     */
    function _passthroughRewards(uint256 _amount) internal override {
        require(initialized, "gauge must me initialized");
        require(_amount > 0, "insufficient amount");
        require(msg.sender == voter, "not voter");
        require(proposalUpdated == true, "proposal must be updated");

        // Reset proposal flag
        proposalUpdated = false;

        bytes32 proposalHash = keccak256(abi.encodePacked(proposal));

        uint256 rewardBalance = IERC20(rewardToken).balanceOf(address(this));
        require(rewardBalance >= _amount, "insufficient rewards");

        _updateRewardForAllTokens();

        IERC20(rewardToken).approve(receiver, _amount);
        IVotiumBribe(receiver).depositBribe(rewardToken, _amount, proposalHash, poolIndex);

        emit Passthrough(msg.sender, rewardToken, _amount, receiver);
    }
}
