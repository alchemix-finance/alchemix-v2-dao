// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IGauge {
    function getReward(address account, address[] memory tokens) external;
}
