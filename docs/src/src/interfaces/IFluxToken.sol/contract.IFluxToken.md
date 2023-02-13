# IFluxToken
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/IFluxToken.sol)

**Inherits:**
IERC20


## Functions
### setMinter

Set the address responsible for minting

*This function reverts if the caller does not have the minter role.*


```solidity
function setMinter(address _minter) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_minter`|`address`|Address that enables the minting of FLUX|


### mint

Mints tokens to a recipient.

*This function reverts if the caller does not have the minter role.*


```solidity
function mint(address _recipient, uint256 _amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_recipient`|`address`|the account to mint tokens to.|
|`_amount`|`uint256`|   the amount of tokens to mint.|


### burnFrom

*Burns `amount` tokens from `account`, deducting from the caller's allowance.*


```solidity
function burnFrom(address _account, uint256 _amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_account`|`address`|The address the burn tokens from.|
|`_amount`|`uint256`| The amount of tokens to burn.|


