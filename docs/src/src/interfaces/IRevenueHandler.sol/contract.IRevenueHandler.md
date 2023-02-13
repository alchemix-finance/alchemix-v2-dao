# IRevenueHandler
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/IRevenueHandler.sol)


## Functions
### claimable

Returns the total amount of debtToken currently claimable by tokenId.

This function will return the amount of claimable accrued revenue up until the most recent checkpoint.

If `checkpoint()` has not been called in the current epoch, then calling `claimable()`

will not return the claimable accrued revenue for the current epoch.


```solidity
function claimable(uint256 tokenId, address debtToken) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|     The tokenId with a claimable balance.|
|`debtToken`|`address`|   The debtToken that is claimable.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of debtToken that is claimable by tokenId.|


### addDebtToken

Add a debtToken to the list of claimable debtTokens.

This function is only callable by the contract owner.


```solidity
function addDebtToken(address debtToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`debtToken`|`address`|   The address of the debt token to add.|


### removeDebtToken

Remove a debtToken from the list of claimable debtTokens.

This function is only callable by the contract owner.


```solidity
function removeDebtToken(address debtToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`debtToken`|`address`|   The address of the debt token to remove.|


### addRevenueToken

Add a revenueToken to the list of claimable revenueTokens.

This function is only callable by the contract owner.


```solidity
function addRevenueToken(address revenueToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`revenueToken`|`address`|   The address of the revenue token to add.|


### removeRevenueToken

Remove a revenueToken from the list of claimable revenueTokens.

This function is only callable by the contract owner.


```solidity
function removeRevenueToken(address revenueToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`revenueToken`|`address`|   The address of the revenue token to remove.|


### setDebtToken

*Add an ERC20 token to the list of recognized revenue tokens.*


```solidity
function setDebtToken(address revenueToken, address debtToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`revenueToken`|`address`|The address of the token to be recognized as revenue.|
|`debtToken`|`address`|   The address of the alchemic-token that will be bought using the revenue token.|


### setPoolAdapter

*Add call data for interactin with a pool adapter.*


```solidity
function setPoolAdapter(address revenueToken, address poolAdapter) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`revenueToken`|`address`|    The address of the revenue token.|
|`poolAdapter`|`address`|     The address of the target pool adapter contract to call.|


### disableRevenueToken

*Disable a revenue token.*


```solidity
function disableRevenueToken(address revenueToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`revenueToken`|`address`|    The address of the revenue token.|


### enableRevenueToken

*Enable a revenue token.*


```solidity
function enableRevenueToken(address revenueToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`revenueToken`|`address`|    The address of the revenue token.|


### setTreasury

*Enable a revenue token.*


```solidity
function setTreasury(address _treasury) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_treasury`|`address`|    The new address of the treasury.|


### setTreasuryPct

*Enable a revenue token.*


```solidity
function setTreasuryPct(uint256 _treasuryPct) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_treasuryPct`|`uint256`| The percentage of revenue to send to the treasury.|


### claim

This function will claim accrued revenue up until the most recent checkpoint.

If `checkpoint()` has not been called in the current epoch, then calling `claim()`

will not claim accrued revenue for the current epoch.

*Claim an alotted amount of alchemic-tokens and burn them to a position in the alchemist.*


```solidity
function claim(uint256 tokenId, address alchemist, uint256 amount, address recipient) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|     The ID of the veALCX position to use.|
|`alchemist`|`address`|   The address of the target alchemist.|
|`amount`|`uint256`|      The amount to claim.|
|`recipient`|`address`|   The recipient of the resulting credit.|


### checkpoint

Checkpoint the current epoch.

This function should be run once per epoch.


```solidity
function checkpoint() external;
```

## Events
### SetPoolAdapter
Emitted when poolAdapter parameters are set for a revenue token.


```solidity
event SetPoolAdapter(address revenueToken, address poolAdapter);
```

### SetDebtToken
Emitted when a debt token is set for a revenue token.


```solidity
event SetDebtToken(address revenueToken, address debtToken);
```

### ClaimRevenue
Emitted when revenue is claimed.


```solidity
event ClaimRevenue(uint256 tokenId, address debtToken, uint256 amount, address recipient);
```

### RevenueRealized
Emitted when revenue is realized during a checkpoint.


```solidity
event RevenueRealized(
    uint256 epochId, address revenueToken, address debtToken, uint256 claimableAmount, uint256 treasuryAmount
);
```

