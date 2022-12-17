// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "../gauges/PassthroughGauge.sol";
import "../gauges/CurveGauge.sol";
import "../gauges/StakingGauge.sol";

contract GaugeFactory {
    address public lastGauge;

    function createStakingGauge(
        address _pool,
        address _bribe,
        address _ve
    ) external returns (address) {
        lastGauge = address(new StakingGauge(_pool, _bribe, _ve, msg.sender));
        return lastGauge;
    }

    function createCurveGauge(address _bribe, address _ve) external returns (address) {
        lastGauge = address(new CurveGauge(_bribe, _ve, msg.sender));
        return lastGauge;
    }

    function createPassthroughGauge(
        address _receiver,
        address _bribe,
        address _ve
    ) external returns (address) {
        lastGauge = address(new PassthroughGauge(_receiver, _bribe, _ve, msg.sender));
        return lastGauge;
    }
}
