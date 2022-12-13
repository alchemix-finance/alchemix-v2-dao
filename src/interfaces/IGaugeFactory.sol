// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IGaugeFactory {
    function admin() external view returns (address);

    function createStakingGauge(
        address,
        address,
        address
    ) external returns (address);

    function createCurveGauge(address, address) external returns (address);

    function createPassthroughGauge(
        address,
        address,
        address
    ) external returns (address);
}
