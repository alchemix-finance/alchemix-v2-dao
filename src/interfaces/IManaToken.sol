// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IManaToken is IERC20 {
    /**
     * @notice Set the address responsible for minting
     * @param _minter Address that enables the minting of MANA
     * @dev This function reverts if the caller does not have the minter role.
     */
    function setMinter(address _minter) external;

    /**
     * @notice Mints tokens to a recipient.
     * @param _recipient the account to mint tokens to.
     * @param _amount    the amount of tokens to mint.
     * @dev This function reverts if the caller does not have the minter role.
     */
    function mint(address _recipient, uint256 _amount) external;

    /**
     * @dev Burns `amount` tokens from `account`, deducting from the caller's allowance.
     * @param _account The address the burn tokens from.
     * @param _amount  The amount of tokens to burn.
     */
    function burnFrom(address _account, uint256 _amount) external;
}
