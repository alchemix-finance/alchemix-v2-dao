// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IBaseGauge {
    function notifyRewardAmount(address token, uint256 amount) external;

    function deliverBribes() external;

    function addBribeRewardToken(address token) external;

    function getReward(address account, address[] memory tokens) external;

    function left(address token) external view returns (uint256);
}
