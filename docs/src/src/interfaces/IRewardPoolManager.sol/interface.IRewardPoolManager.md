# IRewardPoolManager
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/IRewardPoolManager.sol)


## Functions
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
function setRewardPool(address _newRewardPool) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_newRewardPool`|`address`|RewardPool address|


### setPoolToken

Set the poolToken address

*This function reverts if the caller does not have the admin role.*


```solidity
function setPoolToken(address _newPoolToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_newPoolToken`|`address`|PoolToken address|


### setVeALCX

Set the veALCX address

*This function reverts if the caller does not have the admin role.*


```solidity
function setVeALCX(address _newVeALCX) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_newVeALCX`|`address`|veALCX address|


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


## Events
### TreasuryUpdated

```solidity
event TreasuryUpdated(address indexed newTreasury);
```

### AdminUpdated

```solidity
event AdminUpdated(address admin);
```

### RewardPoolUpdated

```solidity
event RewardPoolUpdated(address newRewardPool);
```

### PoolTokenUpdated

```solidity
event PoolTokenUpdated(address newPoolToken);
```

### VeALCXUpdated

```solidity
event VeALCXUpdated(address newVeALCX);
```

### ClaimRewardPoolRewards

```solidity
event ClaimRewardPoolRewards(address indexed claimer, address rewardToken, uint256 rewardAmount);
```

