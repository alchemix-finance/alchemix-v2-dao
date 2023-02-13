// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "./BaseRewardPool4626.sol";

contract RewardPoolFactory {
    address public rewardPoolAddress;

    function createRewardPool(
        uint256 pid,
        address stakingToken,
        address rewardToken,
        address operator,
        address rewardManager,
        address lpToken
    ) external returns (address) {
        rewardPoolAddress = address(
            new BaseRewardPool4626(pid, stakingToken, rewardToken, operator, rewardManager, lpToken)
        );
        return rewardPoolAddress;
    }
}
