// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "src/Bribe.sol";
//please indicate which contract calls this and what is the purpose of this contract
contract BribeFactory {
    function createBribe() external returns (address) {
        return address(new Bribe(msg.sender));
    }
}
