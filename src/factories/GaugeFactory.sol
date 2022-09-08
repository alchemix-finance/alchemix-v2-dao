// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../StakingGauge.sol";

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
}
