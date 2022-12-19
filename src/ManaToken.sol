// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "./interfaces/IManaToken.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title  Mana Token
 * @notice Contract for the Alchemix DAO Mana token
 */
contract ManaToken is ERC20("Mana", "MANA"), IManaToken {
    using SafeERC20 for ERC20;

    /// @dev The address which enables the minting of tokens.
    address public minter;

    constructor(address _minter) {
        minter = _minter;
    }

    /// @dev Modifier which checks that the caller has the minter role.
    modifier onlyMinter() {
        require((msg.sender == minter), "ManaToken: only minter");
        _;
    }

    /// @inheritdoc IManaToken
    function setMinter(address _minter) external onlyMinter {
        minter = _minter;
    }

    /// @inheritdoc IManaToken
    function mint(address _recipient, uint256 _amount) external onlyMinter {
        _mint(_recipient, _amount);
    }

    /// @inheritdoc IManaToken
    function burnFrom(address _account, uint256 _amount) external {
        uint256 newAllowance = allowance(_account, msg.sender) - _amount;

        _approve(_account, msg.sender, newAllowance);
        _burn(_account, _amount);
    }
}
