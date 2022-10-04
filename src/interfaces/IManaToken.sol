// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title  IManaToken
/// @author Alchemix Finance
interface IManaToken is IERC20 {
    function setMinter(address _minter) external;

    function mint(address _recipient, uint256 _amount) external;

    function burn(address _address, uint256 _amount) external;
}
