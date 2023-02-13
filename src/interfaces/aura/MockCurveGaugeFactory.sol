// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "./MockCurveGauge.sol";

contract MockCurveGaugeFactory {
    address public poolAddress;

    function createMockPool(
        string calldata name,
        string calldata symbol,
        address lpToken,
        address[] calldata rewardTokens
    ) external returns (address) {
        poolAddress = address(new MockCurveGauge(name, symbol, lpToken, rewardTokens));
        return poolAddress;
    }
}
