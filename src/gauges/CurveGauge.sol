// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "src/interfaces/IBribe.sol";
import "src/interfaces/IERC20.sol";
import "src/interfaces/IVoter.sol";
import "src/interfaces/IVotingEscrow.sol";
import "src/BaseGauge.sol";
import { IVotiumBribe } from "src/interfaces/votium/IVotiumBribe.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Curve Gauge
/// @notice Gauge to handle distribution of rewards to a given Curve pool
/// @notice Rewards are sent to Curve pool via Votium
/// @dev Pool index is subject to change and proposal id is located in the snapshot url
contract CurveGauge is BaseGauge {
    using SafeERC20 for IERC20;

    event Deposit(address indexed from, uint256 tokenId, uint256 amount);
    event Withdraw(address indexed from, uint256 tokenId, uint256 amount);
    event Passthrough(address indexed from, address token, uint256 amount, address receiver);

    // Votium pool index (subject to change)
    uint256 poolIndex;

    // Rewards token for pool
    address public rewardToken;

    constructor(
        address _bribe,
        address _ve,
        address _voter,
        uint256 _index,
        address _receiver
    ) {
        bribe = _bribe;
        ve = _ve;
        voter = _voter;
        receiver = _receiver;

        poolIndex = _index;

        admin = msg.sender;

        IBribe(bribe).setGauge(address(this));
        rewardToken = IVotingEscrow(ve).ALCX();
        IBribe(bribe).addRewardToken(rewardToken);
        isReward[rewardToken] = true;
        rewards.push(rewardToken);
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "not admin");
        admin = _admin;
    }

    function updateReceiver(address _receiver) external {
        require(msg.sender == admin, "not admin");
        receiver = _receiver;
    }

    function updateIndex(uint256 _poolIndex) external {
        require(msg.sender == admin, "not admin");
        poolIndex = _poolIndex;
    }

    /// @notice Pass rewards to votium contract
    /// @param _amount Amount of rewards
    /// @param _proposal Proposal id from snapshot url
    function _passthroughRewards(uint256 _amount, bytes32 _proposal) internal {
        require(_amount > 0, "insufficient amount");

        bytes32 proposalHash = keccak256(abi.encodePacked(_proposal));

        uint256 rewardBalance = IERC20(rewardToken).balanceOf(address(this));
        require(rewardBalance >= _amount, "insufficient rewards");

        _updateRewardForAllTokens();

        IERC20(rewardToken).approve(receiver, _amount);
        IVotiumBribe(receiver).depositBribe(rewardToken, _amount, proposalHash, poolIndex);

        emit Passthrough(msg.sender, rewardToken, _amount, receiver);
    }

    function notifyRewardAmount(
        address token,
        uint256 _amount,
        bytes32 _proposal
    ) external override lock {
        require(_amount > 0, "insufficient amount");
        if (!isReward[token]) {
            require(rewards.length < MAX_REWARD_TOKENS, "too many rewards tokens");
        }
        // rewards accrue only during the bribe period
        uint256 bribeStart = block.timestamp - (block.timestamp % (7 days)) + BRIBE_LAG;
        uint256 adjustedTstamp = block.timestamp < bribeStart ? bribeStart : bribeStart + 7 days;
        if (rewardRate[token] == 0) _writeRewardPerTokenCheckpoint(token, 0, adjustedTstamp);
        (rewardPerTokenStored[token], lastUpdateTime[token]) = _updateRewardPerToken(token);

        if (block.timestamp >= periodFinish[token]) {
            _safeTransferFrom(token, msg.sender, address(this), _amount);
            rewardRate[token] = _amount / DURATION;
        } else {
            uint256 _remaining = periodFinish[token] - block.timestamp;
            uint256 _left = _remaining * rewardRate[token];
            require(_amount > _left);
            _safeTransferFrom(token, msg.sender, address(this), _amount);
            rewardRate[token] = (_amount + _left) / DURATION;
        }
        require(rewardRate[token] > 0);
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(rewardRate[token] <= balance / DURATION, "Provided reward too high");
        periodFinish[token] = adjustedTstamp + DURATION;
        if (!isReward[token]) {
            isReward[token] = true;
            rewards.push(token);
            IBribe(bribe).addRewardToken(token);
        }

        emit NotifyReward(msg.sender, token, _amount);

        _passthroughRewards(_amount, _proposal);
    }
}
