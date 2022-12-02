// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "../Bribe.sol";

contract BribeFactory {
    address public lastGauge;

    function createBribe() external returns (address) {
        lastGauge = address(new Bribe());
        return lastGauge;
    }
}
