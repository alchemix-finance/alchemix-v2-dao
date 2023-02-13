# IERC20Burnable
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/IERC20Burnable.sol)

**Inherits:**
IERC20

**Author:**
Alchemix Finance


## Functions
### burn

Burns `amount` tokens from the balance of `msg.sender`.


```solidity
function burn(uint256 amount) external returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens to burn.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|If burning the tokens was successful.|


### burnFrom

Burns `amount` tokens from `owner`'s balance.


```solidity
function burnFrom(address owner, uint256 amount) external returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`| The address to burn tokens from.|
|`amount`|`uint256`|The amount of tokens to burn.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|If burning the tokens was successful.|


