// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "src/interfaces/IBribe.sol";
import "src/interfaces/IERC20.sol";
import "src/interfaces/IVoter.sol";
import "src/interfaces/IVotingEscrow.sol";
import "src/BaseGauge.sol";
import { IVotiumBribe } from "src/interfaces/votium/IVotiumBribe.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract CurveGauge is BaseGauge {
    using SafeERC20 for IERC20;

    event Deposit(address indexed from, uint256 tokenId, uint256 amount);
    event Withdraw(address indexed from, uint256 tokenId, uint256 amount);
    event Passthrough(address indexed from, address token, uint256 amount, address receiver);

    uint256 poolIndex;
    address public _token;
    address public votiumReceiver = 0x19BBC3463Dd8d07f55438014b021Fb457EBD4595;

    constructor(
        address _bribe,
        address _ve,
        address _voter,
        uint256 _index
    ) {
        bribe = _bribe;
        ve = _ve;
        voter = _voter;
        receiver = votiumReceiver;

        poolIndex = _index;

        admin = msg.sender;

        IBribe(bribe).setGauge(address(this));
        _token = IVotingEscrow(ve).ALCX();
        IBribe(bribe).addRewardToken(_token);
        isReward[_token] = true;
        rewards.push(_token);
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

    function passthroughRewards(uint256 _amount, bytes32 _proposal) public lock {
        require(_amount > 0);

        bytes32 proposalHash = keccak256(abi.encodePacked(_proposal));

        uint256 rewardBalance = IERC20(_token).balanceOf(address(this));
        require(rewardBalance >= _amount, "insufficient rewards");

        _updateRewardForAllTokens();

        IERC20(_token).approve(receiver, _amount);
        IVotiumBribe(receiver).depositBribe(_token, _amount, proposalHash, poolIndex);

        emit Passthrough(msg.sender, _token, _amount, receiver);
    }

    function notifyRewardAmount(address token, uint256 _amount) external override lock {
        require(_amount > 0);
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
    }
}
