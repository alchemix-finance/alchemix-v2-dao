# RevenueHandler
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/RevenueHandler.sol)

**Inherits:**
[IRevenueHandler](/src/interfaces/IRevenueHandler.sol/contract.IRevenueHandler.md), Ownable


## State Variables
### WEEK

```solidity
uint256 internal constant WEEK = 1 weeks;
```


### BPS

```solidity
uint256 internal constant BPS = 10_000;
```


### veALCX

```solidity
address public veALCX;
```


### debtTokens

```solidity
address[] public debtTokens;
```


### revenueTokens

```solidity
address[] public revenueTokens;
```


### revenueTokenConfigs

```solidity
mapping(address => RevenueTokenConfig) public revenueTokenConfigs;
```


### epochRevenues

```solidity
mapping(uint256 => mapping(address => uint256)) public epochRevenues;
```


### userCheckpoints

```solidity
mapping(uint256 => mapping(address => Claimable)) public userCheckpoints;
```


### currentEpoch

```solidity
uint256 public currentEpoch;
```


### treasury

```solidity
address public treasury;
```


### treasuryPct

```solidity
uint256 public treasuryPct;
```


## Functions
### constructor


```solidity
constructor(address _veALCX, address _treasury, uint256 _treasuryPct) Ownable;
```

### claimable

Returns the total amount of debtToken currently claimable by tokenId.


```solidity
function claimable(uint256 tokenId, address debtToken) external view override returns (uint256);
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


```solidity
function addDebtToken(address debtToken) external override onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`debtToken`|`address`|   The address of the debt token to add.|


### removeDebtToken

Remove a debtToken from the list of claimable debtTokens.


```solidity
function removeDebtToken(address debtToken) external override onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`debtToken`|`address`|   The address of the debt token to remove.|


### addRevenueToken

Add a revenueToken to the list of claimable revenueTokens.


```solidity
function addRevenueToken(address revenueToken) external override onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`revenueToken`|`address`|   The address of the revenue token to add.|


### removeRevenueToken

Remove a revenueToken from the list of claimable revenueTokens.


```solidity
function removeRevenueToken(address revenueToken) external override onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`revenueToken`|`address`|   The address of the revenue token to remove.|


### setDebtToken

*Add an ERC20 token to the list of recognized revenue tokens.*


```solidity
function setDebtToken(address revenueToken, address debtToken) external override onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`revenueToken`|`address`|The address of the token to be recognized as revenue.|
|`debtToken`|`address`|   The address of the alchemic-token that will be bought using the revenue token.|


### setPoolAdapter

*Add call data for interactin with a pool adapter.*


```solidity
function setPoolAdapter(address revenueToken, address poolAdapter) external override onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`revenueToken`|`address`|    The address of the revenue token.|
|`poolAdapter`|`address`|     The address of the target pool adapter contract to call.|


### disableRevenueToken

*Disable a revenue token.*


```solidity
function disableRevenueToken(address revenueToken) external override onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`revenueToken`|`address`|    The address of the revenue token.|


### enableRevenueToken

*Enable a revenue token.*


```solidity
function enableRevenueToken(address revenueToken) external override onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`revenueToken`|`address`|    The address of the revenue token.|


### setTreasury

*Enable a revenue token.*


```solidity
function setTreasury(address _treasury) external override onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_treasury`|`address`|    The new address of the treasury.|


### setTreasuryPct

*Enable a revenue token.*


```solidity
function setTreasuryPct(uint256 _treasuryPct) external override onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_treasuryPct`|`uint256`| The percentage of revenue to send to the treasury.|


### claim

This function will claim accrued revenue up until the most recent checkpoint.

*Claim an alotted amount of alchemic-tokens and burn them to a position in the alchemist.*


```solidity
function claim(uint256 tokenId, address alchemist, uint256 amount, address recipient) external override;
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


```solidity
function checkpoint() public;
```

### _melt


```solidity
function _melt(address revenueToken) internal returns (uint256);
```

### _claimable


```solidity
function _claimable(uint256 tokenId, address debtToken) internal view returns (uint256);
```

## Structs
### RevenueTokenConfig
Parameters to define actions with respect to melting a revenue token for alchemic-tokens.


```solidity
struct RevenueTokenConfig {
    address debtToken;
    address poolAdapter;
    bool disabled;
}
```

### Claimable
A checkpoint on the state of a user's account for a given debtToken


```solidity
struct Claimable {
    uint256 unclaimed;
    uint256 lastClaimEpoch;
}
```

