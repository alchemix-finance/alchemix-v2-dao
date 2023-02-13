# BaseGauge
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/BaseGauge.sol)

**Inherits:**
[IBaseGauge](/src/interfaces/IBaseGauge.sol/contract.IBaseGauge.md)

Implementation of functionality that various gauge types use or extend

Gauges are used to incentivize pools, they emit or passthrough reward tokens


## State Variables
### DURATION

```solidity
uint256 internal constant DURATION = 5 days;
```


### BRIBE_LAG

```solidity
uint256 internal constant BRIBE_LAG = 1 days;
```


### MAX_REWARD_TOKENS

```solidity
uint256 internal constant MAX_REWARD_TOKENS = 16;
```


### PRECISION

```solidity
uint256 internal constant PRECISION = 10 ** 18;
```


### stake

```solidity
address public stake;
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


### rewardToken

```solidity
address public rewardToken;
```


### receiver

```solidity
address public receiver;
```


### gaugeFactory

```solidity
address public gaugeFactory;
```


### derivedSupply

```solidity
uint256 public derivedSupply;
```


### totalSupply

```solidity
uint256 public totalSupply;
```


### supplyNumCheckpoints

```solidity
uint256 public supplyNumCheckpoints;
```


### rewards

```solidity
address[] public rewards;
```


### derivedBalances

```solidity
mapping(address => uint256) public derivedBalances;
```


### rewardRate

```solidity
mapping(address => uint256) public rewardRate;
```


### periodFinish

```solidity
mapping(address => uint256) public periodFinish;
```


### lastUpdateTime

```solidity
mapping(address => uint256) public lastUpdateTime;
```


### rewardPerTokenStored

```solidity
mapping(address => uint256) public rewardPerTokenStored;
```


### lastEarn

```solidity
mapping(address => mapping(address => uint256)) public lastEarn;
```


### userRewardPerTokenStored

```solidity
mapping(address => mapping(address => uint256)) public userRewardPerTokenStored;
```


### tokenIds

```solidity
mapping(address => uint256) public tokenIds;
```


### balanceOf

```solidity
mapping(address => uint256) public balanceOf;
```


### isReward

```solidity
mapping(address => bool) public isReward;
```


### checkpoints
A record of balance checkpoints for each account, by index


```solidity
mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;
```


### numCheckpoints
The number of checkpoints for each account


```solidity
mapping(address => uint256) public numCheckpoints;
```


### supplyCheckpoints
A record of balance checkpoints for each token, by index


```solidity
mapping(uint256 => SupplyCheckpoint) public supplyCheckpoints;
```


### rewardPerTokenCheckpoints
A record of balance checkpoints for each token, by index


```solidity
mapping(address => mapping(uint256 => RewardPerTokenCheckpoint)) public rewardPerTokenCheckpoints;
```


### rewardPerTokenNumCheckpoints
The number of checkpoints for each token


```solidity
mapping(address => uint256) public rewardPerTokenNumCheckpoints;
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
function getVotingStage(uint256 timestamp) public pure returns (VotingStage);
```

### getPriorBalanceIndex

Determine the prior balance for an account as of a block number

*Block number must be a finalized block or else this function will revert to prevent misinformation.*


```solidity
function getPriorBalanceIndex(address account, uint256 timestamp) public view returns (uint256);
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


### getPriorSupplyIndex


```solidity
function getPriorSupplyIndex(uint256 timestamp) public view returns (uint256);
```

### getPriorRewardPerToken


```solidity
function getPriorRewardPerToken(address token, uint256 timestamp) public view returns (uint256, uint256);
```

### rewardsListLength


```solidity
function rewardsListLength() external view returns (uint256);
```

### lastTimeRewardApplicable


```solidity
function lastTimeRewardApplicable(address token) public view returns (uint256);
```

### rewardPerToken


```solidity
function rewardPerToken(address token) public view returns (uint256);
```

### derivedBalance


```solidity
function derivedBalance(address account) public view returns (uint256);
```

### earned


```solidity
function earned(address token, address account) public view returns (uint256);
```

### left

Calculate the time remaining of a rewards period


```solidity
function left(address token) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|    The rewards token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256  Remaining duration of a rewards period|


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

### getReward

Get the rewards form a gauge


```solidity
function getReward(address account, address[] memory tokens) external lock;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|  The account claiming the rewards|
|`tokens`|`address[]`|   The reward tokens being claimed|


### batchRewardPerToken


```solidity
function batchRewardPerToken(address token, uint256 maxRuns) external;
```

### addBribeRewardToken

Distribute the appropriate bribes to a gauge


```solidity
function addBribeRewardToken(address token) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the bribe token|


### batchUpdateRewardPerToken

If the contract will get "out of gas" error on users actions this will be helpful

*Update stored rewardPerToken values without the last one snapshot*


```solidity
function batchUpdateRewardPerToken(address token, uint256 maxRuns) external;
```

### notifyRewardAmount

Distribute the appropriate rewards to a gauge


```solidity
function notifyRewardAmount(address _token, uint256 _amount) external lock;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token`|`address`||
|`_amount`|`uint256`||


### _writeCheckpoint

Update the balance checkpoint of a given account


```solidity
function _writeCheckpoint(address account, uint256 balance) internal;
```

### _writeRewardPerTokenCheckpoint


```solidity
function _writeRewardPerTokenCheckpoint(address token, uint256 reward, uint256 timestamp) internal;
```

### _writeSupplyCheckpoint


```solidity
function _writeSupplyCheckpoint() internal;
```

### _batchRewardPerToken


```solidity
function _batchRewardPerToken(address token, uint256 maxRuns) internal returns (uint256, uint256);
```

### _calcRewardPerToken


```solidity
function _calcRewardPerToken(
    address token,
    uint256 timestamp1,
    uint256 timestamp0,
    uint256 supply,
    uint256 startTimestamp
) internal view returns (uint256, uint256);
```

### _updateRewardForAllTokens


```solidity
function _updateRewardForAllTokens() internal;
```

### _updateRewardPerToken


```solidity
function _updateRewardPerToken(address token, uint256 maxRuns, bool actualLast) internal returns (uint256, uint256);
```

### _safeTransfer


```solidity
function _safeTransfer(address token, address to, uint256 value) internal;
```

### _safeTransferFrom


```solidity
function _safeTransferFrom(address token, address from, address to, uint256 value) internal;
```

### _safeApprove


```solidity
function _safeApprove(address token, address spender, uint256 value) internal;
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


