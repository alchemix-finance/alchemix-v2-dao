// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "solmate/tokens/ERC20.sol";

contract gALCX is ERC20 {

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol, 18) {

    }

}