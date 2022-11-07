// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IALCXSource} from "../../src/interfaces/IALCXSource.sol";

contract ALCXSource is IALCXSource {

    IERC20 public alcx = IERC20(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
    mapping(address => uint256) public balances;

    function getStakeTotalDeposited(address _user, uint256) external view returns (uint256) {
        return balances[_user];
    }

    function claim(uint256) external {

    }

    function deposit(uint256, uint256 _depositAmount) external {
        alcx.transferFrom(msg.sender, address(this), _depositAmount);
        balances[msg.sender] += _depositAmount;
    }

    function withdraw(uint256, uint256 _withdrawAmount) external {
        require(balances[msg.sender] >= _withdrawAmount, "Not enough balance");
        balances[msg.sender] -= _withdrawAmount;
        alcx.transfer(msg.sender, _withdrawAmount);
    }
}