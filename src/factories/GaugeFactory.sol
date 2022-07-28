// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import '../Gauge.sol';
import '../interfaces/IPairFactory.sol';

contract GaugeFactory {
    address public last_gauge;
    address public admin;
    address immutable pairFactory;

    constructor(address _pairFactory) {
        admin = msg.sender;
        pairFactory = _pairFactory;
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin);
        admin = _admin;
    }

    function createGauge(address _pool, address _bribe, address _ve) external returns (address) {
        bool isPair = IPairFactory(pairFactory).isPair(_pool);
        last_gauge = address(new Gauge(_pool, _bribe, _ve, msg.sender, isPair));
        return last_gauge;
    }

    function createGaugeSingle(address _pool, address _bribe, address _ve, address _voter) external returns (address) {
        bool isPair = IPairFactory(pairFactory).isPair(_pool);
        last_gauge = address(new Gauge(_pool, _bribe, _ve, _voter, isPair));
        return last_gauge;
    }
}
