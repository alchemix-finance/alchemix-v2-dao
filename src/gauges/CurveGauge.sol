// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "src/interfaces/IBribe.sol";
import "src/interfaces/IERC20.sol";
import "src/interfaces/IVoter.sol";
import "src/interfaces/IVotingEscrow.sol";
import "src/BaseGauge.sol";
import { VotiumBribe } from "src/interfaces/votium/VotiumBribe.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "lib/forge-std/src/console2.sol";

contract CurveGauge is BaseGauge {
    using SafeERC20 for IERC20;

    event Deposit(address indexed from, uint256 tokenId, uint256 amount);
    event Withdraw(address indexed from, uint256 tokenId, uint256 amount);
    event Passthrough(address indexed from, address token, uint256 amount, address receiver);

    uint256[] public poolIndexes;
    address public _token;

    constructor(
        address _receiver,
        address _bribe,
        address _ve,
        address _voter
    ) {
        bribe = _bribe;
        ve = _ve;
        voter = _voter;
        receiver = _receiver;

        poolIndexes.push(34);
        poolIndexes.push(46);
        poolIndexes.push(105);

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

    function updateIndex(uint256 _pool, uint256 _index) external {
        require(msg.sender == admin, "not admin");
        poolIndexes[_pool] = _index;
    }

    function passthroughRewards(uint256 _amount, bytes32 _proposal) public lock {
        require(_amount > 0);

        uint256 rewardBalance = IERC20(_token).balanceOf(address(this));
        require(rewardBalance >= _amount, "insufficient rewards");

        _updateRewardForAllTokens();

        IERC20(_token).approve(receiver, _amount);
        VotiumBribe(receiver).depositBribe(_token, _amount, _proposal, poolIndexes[0]);

        emit Passthrough(msg.sender, _token, _amount, receiver);
    }

    function notifyRewardAmount(address _token, uint256 _amount) external override lock {
        require(_amount > 0);
        if (!isReward[_token]) {
            require(rewards.length < MAX_REWARD_TOKENS, "too many rewards tokens");
        }
        // rewards accrue only during the bribe period
        uint256 bribeStart = block.timestamp - (block.timestamp % (7 days)) + BRIBE_LAG;
        uint256 adjustedTstamp = block.timestamp < bribeStart ? bribeStart : bribeStart + 7 days;
        if (rewardRate[_token] == 0) _writeRewardPerTokenCheckpoint(_token, 0, adjustedTstamp);
        (rewardPerTokenStored[_token], lastUpdateTime[_token]) = _updateRewardPerToken(_token);

        if (block.timestamp >= periodFinish[_token]) {
            _safeTransferFrom(_token, msg.sender, address(this), _amount);
            rewardRate[_token] = _amount / DURATION;
        } else {
            uint256 _remaining = periodFinish[_token] - block.timestamp;
            uint256 _left = _remaining * rewardRate[_token];
            require(_amount > _left);
            _safeTransferFrom(_token, msg.sender, address(this), _amount);
            rewardRate[_token] = (_amount + _left) / DURATION;
        }
        require(rewardRate[_token] > 0);
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(rewardRate[_token] <= balance / DURATION, "Provided reward too high");
        periodFinish[_token] = adjustedTstamp + DURATION;
        if (!isReward[_token]) {
            isReward[_token] = true;
            rewards.push(_token);
            IBribe(bribe).addRewardToken(_token);
        }

        emit NotifyReward(msg.sender, _token, _amount);
    }
}
