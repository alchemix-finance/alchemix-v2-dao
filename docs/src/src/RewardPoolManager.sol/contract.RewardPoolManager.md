# RewardPoolManager
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/RewardPoolManager.sol)

**Inherits:**
[IRewardPoolManager](/src/interfaces/IRewardPoolManager.sol/interface.IRewardPoolManager.md)


## State Variables
### MAX_REWARD_POOL_TOKENS

```solidity
uint256 internal constant MAX_REWARD_POOL_TOKENS = 10;
```


### admin

```solidity
address public admin;
```


### pendingAdmin

```solidity
address public pendingAdmin;
```


### veALCX

```solidity
address public veALCX;
```


### rewardPool

```solidity
address public rewardPool;
```


### treasury

```solidity
address public treasury;
```


### poolToken

```solidity
address public poolToken;
```


### rewardPoolTokens

```solidity
address[] public rewardPoolTokens;
```


### isRewardPoolToken

```solidity
mapping(address => bool) public isRewardPoolToken;
```


## Functions
### constructor


```solidity
constructor(address _admin, address _veALCX, address _poolToken, address _rewardPool, address _treasury);
```

### setAdmin

Set the address responsible for administration

*This function reverts if the caller does not have the admin role.*


```solidity
function setAdmin(address _admin) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_admin`|`address`|Address that enables the administration of FLUX|


### acceptAdmin

Accept the address responsible for administration

*This function reverts if the caller does not have the pendingAdmin role.*


```solidity
function acceptAdmin() external;
```

### setTreasury

Set the treasury address

*This function reverts if the caller does not have the admin role.*


```solidity
function setTreasury(address _treasury) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_treasury`|`address`|Treasury address|


### setRewardPool

Set the rewardPool address

*This function reverts if the caller does not have the admin role.*


```solidity
function setRewardPool(address _rewardPool) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_rewardPool`|`address`||


### setPoolToken

Set the poolToken address

*This function reverts if the caller does not have the admin role.*


```solidity
function setPoolToken(address _poolToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_poolToken`|`address`||


### setVeALCX

Set the veALCX address

*This function reverts if the caller does not have the admin role.*


```solidity
function setVeALCX(address _veALCX) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_veALCX`|`address`||


### depositIntoRewardPool

Deposit amount into rewardPool


```solidity
function depositIntoRewardPool(uint256 _amount) external returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Amount to deposit|


### withdrawFromRewardPool

Withdraw amount from rewardPool


```solidity
function withdrawFromRewardPool(uint256 _amount) external returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Amount to withdraw|


### claimRewardPoolRewards

Claim rewards from the rewardPool


```solidity
function claimRewardPoolRewards() external;
```

### addRewardPoolToken

Add a rewardPoolToken


```solidity
function addRewardPoolToken(address _token) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token`|`address`|Address of the token to add|


### addRewardPoolTokens

Add multiple rewardPoolTokens


```solidity
function addRewardPoolTokens(address[] calldata _tokens) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokens`|`address[]`|Addresses of the tokens to add|


### swapOutRewardPoolToken

Swap a rewardPoolToken


```solidity
function swapOutRewardPoolToken(uint256 i, address oldToken, address newToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`i`|`uint256`|Index of the token to swap|
|`oldToken`|`address`|Address of the token to remove|
|`newToken`|`address`|Address of the token to add|


### _addRewardPoolToken


```solidity
function _addRewardPoolToken(address token) internal;
```

