// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "../StakingGauge.sol";
import "../PassthroughGauge.sol";
import "../gauges/CurveGauge.sol";
import "../gauges/SushiGauge.sol";

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

    function createSushiGauge(
        address _receiver,
        address _bribe,
        address _ve
    ) external returns (address) {
        lastGauge = address(new SushiGauge(_receiver, _bribe, _ve, msg.sender));
        return lastGauge;
    }
}
