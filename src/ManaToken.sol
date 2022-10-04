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

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(address _address, uint256 _amount) public virtual {
        _burn(_address, _amount);
    }
}
