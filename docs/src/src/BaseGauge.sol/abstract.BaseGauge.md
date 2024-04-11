# BaseGauge
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/BaseGauge.sol)

**Inherits:**
[IBaseGauge](/src/interfaces/IBaseGauge.sol/interface.IBaseGauge.md)

Implementation of functionality that various gauge types use or extend

Gauges are used to incentivize pools, they emit or passthrough reward tokens


## State Variables
### DURATION

```solidity
uint256 internal constant DURATION = 2 weeks;
```


### BRIBE_LAG

```solidity
uint256 internal constant BRIBE_LAG = 1 days;
```


### MAX_REWARD_TOKENS

```solidity
uint256 internal constant MAX_REWARD_TOKENS = 16;
```


### ve

```solidity
address public ve;
```


### bribe

```solidity
address public bribe;
```


### voter

```solidity
address public voter;
```


### admin

```solidity
address public admin;
```


### pendingAdmin

```solidity
address public pendingAdmin;
```


### receiver

```solidity
address public receiver;
```


### rewardToken

```solidity
address public rewardToken;
```


### _unlocked

```solidity
uint256 internal _unlocked = 1;
```


## Functions
### lock


```solidity
modifier lock();
```

### getVotingStage


```solidity
function getVotingStage(uint256 timestamp) external pure returns (VotingStage);
```

### setAdmin


```solidity
function setAdmin(address _admin) external;
```

### acceptAdmin


```solidity
function acceptAdmin() external;
```

### updateReceiver


```solidity
function updateReceiver(address _receiver) external;
```

### notifyRewardAmount

Distribute the appropriate rewards to a gauge


```solidity
function notifyRewardAmount(uint256 _amount) external lock;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`||


### _safeTransfer


```solidity
function _safeTransfer(address token, address to, uint256 value) internal;
```

### _safeTransferFrom


```solidity
function _safeTransferFrom(address token, address from, address to, uint256 value) internal;
```

### _passthroughRewards

Override function to implement passthrough logic


```solidity
function _passthroughRewards(uint256 _amount) internal virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Amount of rewards|


