# IWETH9
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/IWETH9.sol)

**Inherits:**
IERC20, IERC20Metadata


## Functions
### deposit

Deposits `msg.value` ethereum into the contract and mints `msg.value` tokens.


```solidity
function deposit() external payable;
```

### withdraw

Burns `amount` tokens to retrieve `amount` ethereum from the contract.

*This version of WETH utilizes the `transfer` function which hard codes the amount of gas
that is allowed to be utilized to be exactly 2300 when receiving ethereum.*


```solidity
function withdraw(uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens to burn.|


