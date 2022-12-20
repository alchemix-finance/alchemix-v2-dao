// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.12;

import "openzeppelin-contracts/contracts/access/IAccessControl.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title  IAlchemixToken
/// @author Alchemix Finance
interface IAlchemixToken is IAccessControl, IERC20 {
    function mint(address _recipient, uint256 _amount) external;
}
