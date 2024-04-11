# IBribe
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/IBribe.sol)


## Functions
### setGauge

Set the gauge a bribe belongs to


```solidity
function setGauge(address _gauge) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_gauge`|`address`|The address of the gauge|


### periodFinish


```solidity
function periodFinish(address token) external view returns (uint256);
```

### getEpochStart

Calculate the epoch start time


```solidity
function getEpochStart(uint256 timestamp) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`timestamp`|`uint256`|Provided timstamp|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256  Timestamp of start time|


### rewardsListLength


```solidity
function rewardsListLength() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Length of the rewards address array|


### notifyRewardAmount

Distribute the appropriate bribes to a gauge


```solidity
function notifyRewardAmount(address token, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|    The address of the bribe token|
|`amount`|`uint256`|   The amount of bribes being sent|


### lastTimeRewardApplicable

Return the current reward period or previous periodFinish if the reward has ended


```solidity
function lastTimeRewardApplicable(address token) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|Address of the reward token to check|


### rewards


```solidity
function rewards(uint256 i) external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address Address of a reward token given the index|


### getPriorBalanceIndex

Determine the prior balance for an account as of a timestamp


```solidity
function getPriorBalanceIndex(uint256 tokenId, uint256 timestamp) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|  Id of the token check|
|`timestamp`|`uint256`|The timestamp to get the balance at|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256  The balance the account had as of the given timestamp|


### getRewardForOwner

Used by Voter to allow batched reward claims


```solidity
function getRewardForOwner(uint256 tokenId, address[] memory tokens) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|Id of the token who's rewards are being claimed|
|`tokens`|`address[]`| List of tokens being claimed|


### addRewardToken

Add a token to the rewards array


```solidity
function addRewardToken(address token) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token|


### swapOutRewardToken

Update a token in the rewards array


```solidity
function swapOutRewardToken(uint256 i, address oldToken, address newToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`i`|`uint256`|       Index of the existing token|
|`oldToken`|`address`|Token being replaced|
|`newToken`|`address`|Token being added|


### getPriorVotingIndex


```solidity
function getPriorVotingIndex(uint256 timestamp) external view returns (uint256);
```

### earned


```solidity
function earned(address token, uint256 tokenId) external view returns (uint256);
```

### deposit


```solidity
function deposit(uint256 amount, uint256 tokenId) external;
```

### withdraw


```solidity
function withdraw(uint256 amount, uint256 tokenId) external;
```

### resetVoting

Resets the totalVoting count which calculates
the total amount of votes for an epoch

*Each new epoch marks the start of a new totalVoting counter
in order calculate who is eligible to earn bribes*


```solidity
function resetVoting() external;
```

### totalVoting

Returns the amount of votes for a single epoch


```solidity
function totalVoting() external view returns (uint256);
```

### totalSupply

Returns the total amount of votes from all epochs


```solidity
function totalSupply() external view returns (uint256);
```

## Events
### NotifyReward
Emitted when the bribe amount is calculated for a given token


```solidity
event NotifyReward(address indexed from, address indexed reward, uint256 epoch, uint256 amount);
```

### GaugeUpdated
Emitted when a new gauge is set.


```solidity
event GaugeUpdated(address gauge);
```

### RewardTokenAdded
Emitted when a new reward token is added.


```solidity
event RewardTokenAdded(address token);
```

### RewardTokenSwapped
Emitted when a reward token is swapped for another token.


```solidity
event RewardTokenSwapped(address oldToken, address newToken);
```

### Deposit

```solidity
event Deposit(address indexed from, uint256 tokenId, uint256 amount);
```

### Withdraw

```solidity
event Withdraw(address indexed from, uint256 tokenId, uint256 amount);
```

### ClaimRewards

```solidity
event ClaimRewards(address indexed from, address indexed reward, uint256 amount);
```

## Structs
### Checkpoint
Checkpoint for marking balance


```solidity
struct Checkpoint {
    uint256 timestamp;
    uint256 balanceOf;
}
```

### SupplyCheckpoint
Checkpoint for marking supply


```solidity
struct SupplyCheckpoint {
    uint256 timestamp;
    uint256 supply;
}
```

### VotingCheckpoint

```solidity
struct VotingCheckpoint {
    uint256 timestamp;
    uint256 votes;
}
```

