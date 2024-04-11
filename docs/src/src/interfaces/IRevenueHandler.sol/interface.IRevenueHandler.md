# IRevenueHandler
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/IRevenueHandler.sol)


## Functions
### claimable

Returns the total amount of token currently claimable by tokenId.

This function will return the amount of claimable accrued revenue up until the most recent checkpoint.

If `checkpoint()` has not been called in the current epoch, then calling `claimable()`

will not return the claimable accrued revenue for the current epoch.


```solidity
function claimable(uint256 tokenId, address token) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|     The tokenId with a claimable balance.|
|`token`|`address`|   The token that is claimable.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of token that is claimable by tokenId.|


### addRevenueToken

Add a revenueToken to the list of claimable revenueTokens.

This function is only callable by the contract owner.


```solidity
function addRevenueToken(address revenueToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`revenueToken`|`address`|The address of the revenue token to add.|


### removeRevenueToken

Remove a revenueToken from the list of claimable revenueTokens.

This function is only callable by the contract owner.


```solidity
function removeRevenueToken(address revenueToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`revenueToken`|`address`|The address of the revenue token to remove.|


### addAlchemicToken

Add an alchemic-token to the list of recognized alchemic-tokens.

This function is only callable by the contract owner.

*the alchemic-token will be derived from the alchemist.*


```solidity
function addAlchemicToken(address alchemist) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`alchemist`|`address`|The address of the alchemist to add.|


### removeAlchemicToken

Remove an alchemic-token from the list of recognized alchemic-tokens.

This function is only callable by the contract owner.

*the alchemic-token will be derived from the alchemist.*


```solidity
function removeAlchemicToken(address alchemist) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`alchemist`|`address`|The address of the alchemist to remove.|


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
|`revenueToken`|`address`| The address of the revenue token.|
|`poolAdapter`|`address`|  The address of the target pool adapter contract to call.|


### disableRevenueToken

*Disable a revenue token.*


```solidity
function disableRevenueToken(address revenueToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`revenueToken`|`address`|The address of the revenue token.|


### enableRevenueToken

*Enable a revenue token.*


```solidity
function enableRevenueToken(address revenueToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`revenueToken`|`address`|The address of the revenue token.|


### setTreasury

*Enable a revenue token.*


```solidity
function setTreasury(address _treasury) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_treasury`|`address`|The new address of the treasury.|


### setTreasuryPct

*Enable a revenue token.*


```solidity
function setTreasuryPct(uint256 _treasuryPct) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_treasuryPct`|`uint256`|The percentage of revenue to send to the treasury.|


### claim

This function will claim accrued revenue up until the most recent checkpoint.

If `checkpoint()` has not been called in the current epoch, then calling `claim()`

will not claim accrued revenue for the current epoch.

*Claim an alotted amount of alchemic-tokens and burn them to a position in the alchemist.*

*If token being claimed is not an alchemic-token, then it will be sent to the recipient.*


```solidity
function claim(uint256 tokenId, address token, address alchemist, uint256 amount, address recipient) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|     The ID of the veALCX position to use.|
|`token`|`address`|       The address of the token to claim.|
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
### TreasuryUpdated
Emitted when the address of the treasury is updated.


```solidity
event TreasuryUpdated(address treasury);
```

### TreasuryPctUpdated
Emitted when the treasury PCT is updated.


```solidity
event TreasuryPctUpdated(uint256 treasuryPct);
```

### DebtTokenAdded
Emitted when a debt token is added.


```solidity
event DebtTokenAdded(address debtToken);
```

### DebtTokenRemoved
Emitted when a debt token is removed.


```solidity
event DebtTokenRemoved(address debtToken);
```

### RevenueTokenTokenAdded
Emitted when a revenue token is added.


```solidity
event RevenueTokenTokenAdded(address revenueToken);
```

### RevenueTokenTokenRemoved
Emitted when a revenue token is removed.


```solidity
event RevenueTokenTokenRemoved(address revenueToken);
```

### AlchemicTokenAdded
Emitted when alchemic-token is added.


```solidity
event AlchemicTokenAdded(address alchemist, address alchemicToken);
```

### AlchemicTokenRemoved
Emitted when alchemic-token is removed.


```solidity
event AlchemicTokenRemoved(address alchemist, address alchemicToken);
```

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

