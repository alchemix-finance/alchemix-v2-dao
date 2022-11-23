// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../StakingGauge.sol";
import "../gauges/CurveGauge.sol";

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

    function createCurveGauge(
        address _bribe,
        address _ve,
        uint256 _index
    ) external returns (address) {
        lastGauge = address(new CurveGauge(_bribe, _ve, msg.sender, _index));
        return lastGauge;
    }
}
