// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "src/Bribe.sol";

/// @title Bribe Factory
/// @notice Factory to create bribe contracts
/// @dev Voter will call createBribe for each new gauge created
contract BribeFactory {
    function createBribe() external returns (address) {
        return address(new Bribe(msg.sender));
    }
}
