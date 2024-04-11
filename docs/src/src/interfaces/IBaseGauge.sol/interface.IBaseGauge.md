# IBaseGauge
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/IBaseGauge.sol)


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
function notifyRewardAmount(uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|   The amount of rewards being sent|


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

