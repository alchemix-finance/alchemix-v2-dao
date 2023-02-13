# IBaseGauge
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/IBaseGauge.sol)


## Functions
### setAdmin


```solidity
function setAdmin(address _admin) external;
```

### acceptAdmin


```solidity
function acceptAdmin() external;
```

### notifyRewardAmount

Distribute the appropriate rewards to a gauge


```solidity
function notifyRewardAmount(address token, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|    The address of the reward token|
|`amount`|`uint256`|   The amount of rewards being sent|


### addBribeRewardToken

Distribute the appropriate bribes to a gauge

Add a bribe token to a gauge


```solidity
function addBribeRewardToken(address token) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the bribe token|


### earned

Estimation, not exact until the supply > rewardPerToken calculations have run


```solidity
function earned(address token, address account) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|  address of reward token|
|`account`|`address`|account claiming rewards|


### getReward

Get the rewards form a gauge


```solidity
function getReward(address account, address[] memory tokens) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|  The account claiming the rewards|
|`tokens`|`address[]`|   The reward tokens being claimed|


### getPriorBalanceIndex

Determine the prior balance for an account as of a block number

*Block number must be a finalized block or else this function will revert to prevent misinformation.*


```solidity
function getPriorBalanceIndex(address account, uint256 timestamp) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address of the account to check|
|`timestamp`|`uint256`|The timestamp to get the balance at|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The balance the account had as of the given block|


### left

Calculate the time remaining of a rewards period


```solidity
function left(address token) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|    The rewards token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256  Remaining duration of a rewards period|


### batchUpdateRewardPerToken

If the contract will get "out of gas" error on users actions this will be helpful

*Update stored rewardPerToken values without the last one snapshot*


```solidity
function batchUpdateRewardPerToken(address token, uint256 maxRuns) external;
```

## Events
### NotifyReward
Emitted when the reward amount is calculated for a given token


```solidity
event NotifyReward(address indexed from, address indexed reward, uint256 amount);
```

### ClaimRewards
Emitted when rewards are claimed


```solidity
event ClaimRewards(address indexed from, address indexed reward, uint256 amount);
```

### Passthrough
Emitted when rewards are passed to a gauge


```solidity
event Passthrough(address indexed from, address token, uint256 amount, address receiver);
```

## Structs
### Checkpoint
A checkpoint for marking balance


```solidity
struct Checkpoint {
    uint256 timestamp;
    uint256 balanceOf;
}
```

### RewardPerTokenCheckpoint
A checkpoint for marking reward rate


```solidity
struct RewardPerTokenCheckpoint {
    uint256 timestamp;
    uint256 rewardPerToken;
}
```

### SupplyCheckpoint
A checkpoint for marking supply


```solidity
struct SupplyCheckpoint {
    uint256 timestamp;
    uint256 supply;
}
```

## Enums
### VotingStage

```solidity
enum VotingStage {
    BribesPhase,
    VotesPhase,
    RewardsPhase
}
```

