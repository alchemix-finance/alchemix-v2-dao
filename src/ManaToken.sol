// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title ManaToken
///
/// @dev This is the contract for the Alchemix DAO Mana token
contract ManaToken is ERC20("Mana", "MANA") {
    using SafeERC20 for ERC20;

    /// @dev The address which enables the minting of tokens.
    address public minter;

    constructor(address _minter) {
        minter = _minter;
    }

    /// @dev A modifier which checks that the caller has the minter role.
    modifier onlyMinter() {
        require((msg.sender == minter), "ManaToken: only minter");
        _;
    }

    function setMinter(address _minter) external onlyMinter {
        minter = _minter;
    }

    /// @dev Mints tokens to a recipient.
    ///
    /// This function reverts if the caller does not have the minter role.
    ///
    /// @param _recipient the account to mint tokens to.
    /// @param _amount    the amount of tokens to mint.
    function mint(address _recipient, uint256 _amount) external onlyMinter {
        _mint(_recipient, _amount);
    }

    /// @dev Burns `amount` tokens from `account`, deducting from the caller's allowance.
    ///
    /// @param _account The address the burn tokens from.
    /// @param _amount  The amount of tokens to burn.
    function burnFrom(address _account, uint256 _amount) external {
        uint256 newAllowance = allowance(_account, msg.sender) - _amount;

        _approve(_account, msg.sender, newAllowance);
        _burn(_account, _amount);
    }
}
