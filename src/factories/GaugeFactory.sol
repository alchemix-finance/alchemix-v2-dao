// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "src/gauges/PassthroughGauge.sol";
import "src/gauges/CurveGauge.sol";

contract GaugeFactory {
    function createCurveGauge(address _bribe, address _ve) external returns (address) {
        return address(new CurveGauge(_bribe, _ve, msg.sender));
    }

    function createPassthroughGauge(address _receiver, address _bribe, address _ve) external returns (address) {
        return address(new PassthroughGauge(_receiver, _bribe, _ve, msg.sender));
    }
}
