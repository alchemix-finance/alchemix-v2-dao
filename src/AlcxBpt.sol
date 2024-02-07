// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract AlcxBpt is ERC20("AlcxBpt", "ALCXBPT") {
    using SafeERC20 for ERC20;

    /// @dev The address which enables the minting of tokens.
    address public minter;

    constructor(address _minter) {
        require(_minter != address(0), "AlcxBpt: minter cannot be zero address");
        minter = _minter;
    }

    /// @dev Modifier which checks that the caller has the minter role.
    modifier onlyMinter() {
        require((msg.sender == minter), "AlcxBpt: only minter");
        _;
    }

    function setMinter(address _minter) external onlyMinter {
        require(_minter != address(0), "AlcxBpt: minter cannot be zero address");
        minter = _minter;
    }

    function mint(address _recipient, uint256 _amount) external onlyMinter {
        _mint(_recipient, _amount);
    }

    function burnFrom(address _account, uint256 _amount) external {
        uint256 newAllowance = allowance(_account, msg.sender) - _amount;

        _approve(_account, msg.sender, newAllowance);
        _burn(_account, _amount);
    }
}
