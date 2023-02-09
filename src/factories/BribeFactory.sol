// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "src/Bribe.sol";

contract BribeFactory {
    address public bribeAddress;

    function createBribe() external returns (address) {
        bribeAddress = address(new Bribe(msg.sender));
        return bribeAddress;
    }
}
