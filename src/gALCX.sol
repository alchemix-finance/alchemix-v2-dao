// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

import {StakingPools} from "./interfaces/StakingPools.sol";

contract gALCX is ERC20 {

    IERC20 public alcx = IERC20(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
    StakingPools public pools = StakingPools(0xAB8e74017a8Cc7c15FFcCd726603790d26d7DeCa);
    uint public poolId = 1;
    uint public constant exchangeRatePrecision = 1e18;
    uint public exchangeRate = exchangeRatePrecision;


    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol, 18) {
        // Set infinite approval
        bool success = alcx.approve(address(pools), type(uint).max);
    }

    function bumpExchangeRate() public {
        // Claim from pool
        pools.claim(poolId);
        // Bump exchange rate
        uint balance = alcx.balanceOf(address(this));

        if (balance > 0) {
            exchangeRate += (balance * exchangeRatePrecision) / totalSupply;
            // Restake
            pools.deposit(poolId, balance);
        }
    }

    function stake(uint amount) external {
        // Get current exchange rate between ALCX and gALCX
        bumpExchangeRate();
        // Then receive new deposits
        bool success = alcx.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");
        pools.deposit(poolId, amount);
        // gAmount always <= amount
        uint gAmount = amount * exchangeRatePrecision / exchangeRate;
        _mint(msg.sender, gAmount);
    }

    function unstake(uint gAmount) external {
        bumpExchangeRate();
        uint amount = gAmount * exchangeRate / exchangeRatePrecision;
        _burn(msg.sender, gAmount);
        // Withdraw ALCX and send to user
        pools.withdraw(poolId, amount);
        bool success = alcx.transfer(msg.sender, amount); // Should return true or revert, but doesn't hurt
        require(success, "Transfer failed"); 
    }
}