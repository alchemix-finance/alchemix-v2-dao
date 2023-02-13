# FluxToken
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/FluxToken.sol)

**Inherits:**
ERC20, [IFluxToken](/src/interfaces/IFluxToken.sol/contract.IFluxToken.md)

Contract for the Alchemix DAO Flux token


## State Variables
### minter
*The address which enables the minting of tokens.*


```solidity
address public minter;
```


## Functions
### constructor


```solidity
constructor(address _minter);
```

### onlyMinter

*Modifier which checks that the caller has the minter role.*


```solidity
modifier onlyMinter();
```

### setMinter

Set the address responsible for minting

*This function reverts if the caller does not have the minter role.*


```solidity
function setMinter(address _minter) external onlyMinter;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_minter`|`address`|Address that enables the minting of FLUX|


### mint

Mints tokens to a recipient.

*This function reverts if the caller does not have the minter role.*


```solidity
function mint(address _recipient, uint256 _amount) external onlyMinter;
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


