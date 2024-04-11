# Bribe
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/Bribe.sol)

**Inherits:**
[IBribe](/src/interfaces/IBribe.sol/interface.IBribe.md)

Implementation of bribe contract to be used with gauges


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


### supplyNumCheckpoints
The number of checkpoints


```solidity
uint256 public supplyNumCheckpoints;
```


### votingNumCheckpoints

```solidity
uint256 public votingNumCheckpoints;
```


### totalSupply

```solidity
uint256 public totalSupply;
```


### totalVoting

```solidity
uint256 public totalVoting;
```


### veALCX

```solidity
address public immutable veALCX;
```


### voter

```solidity
address public immutable voter;
```


### gauge

```solidity
address public gauge;
```


### rewards

```solidity
address[] public rewards;
```


### checkpoints
A record of balance checkpoints for each account, by index


```solidity
mapping(uint256 => mapping(uint256 => Checkpoint)) public checkpoints;
```


### numCheckpoints
The number of checkpoints for each account


```solidity
mapping(uint256 => uint256) public numCheckpoints;
```


### supplyCheckpoints
A record of balance checkpoints for each token, by index


```solidity
mapping(uint256 => SupplyCheckpoint) public supplyCheckpoints;
```


### votingCheckpoints

```solidity
mapping(uint256 => VotingCheckpoint) public votingCheckpoints;
```


### isReward

```solidity
mapping(address => bool) public isReward;
```


### tokenRewardsPerEpoch

```solidity
mapping(address => mapping(uint256 => uint256)) public tokenRewardsPerEpoch;
```


### balanceOf

```solidity
mapping(uint256 => uint256) public balanceOf;
```


### periodFinish

```solidity
mapping(address => uint256) public periodFinish;
```


### lastEarn

```solidity
mapping(address => mapping(uint256 => uint256)) public lastEarn;
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

### constructor


```solidity
constructor(address _voter);
```

### getEpochStart

Calculate the epoch start time


```solidity
function getEpochStart(uint256 timestamp) public pure returns (uint256);
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


### lastTimeRewardApplicable

Return the current reward period or previous periodFinish if the reward has ended


```solidity
function lastTimeRewardApplicable(address token) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|Address of the reward token to check|


### setGauge

Set the gauge a bribe belongs to


```solidity
function setGauge(address _gauge) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_gauge`|`address`|The address of the gauge|


### notifyRewardAmount

Distribute the appropriate bribes to a gauge


```solidity
function notifyRewardAmount(address token, uint256 amount) external lock;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|    The address of the bribe token|
|`amount`|`uint256`|   The amount of bribes being sent|


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
function swapOutRewardToken(uint256 oldTokenIndex, address oldToken, address newToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`oldTokenIndex`|`uint256`||
|`oldToken`|`address`|Token being replaced|
|`newToken`|`address`|Token being added|


### getPriorBalanceIndex

Determine the prior balance for an account as of a timestamp


```solidity
function getPriorBalanceIndex(uint256 tokenId, uint256 timestamp) public view returns (uint256);
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


### getPriorVotingIndex


```solidity
function getPriorVotingIndex(uint256 timestamp) public view returns (uint256);
```

### earned


```solidity
function earned(address token, uint256 tokenId) public view returns (uint256);
```

### getRewardForOwner

Used by Voter to allow batched reward claims


```solidity
function getRewardForOwner(uint256 tokenId, address[] memory tokens) external lock;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|Id of the token who's rewards are being claimed|
|`tokens`|`address[]`| List of tokens being claimed|


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

### _addRewardToken


```solidity
function _addRewardToken(address token) internal;
```

### _writeCheckpoint


```solidity
function _writeCheckpoint(uint256 tokenId, uint256 balance) internal;
```

### _writeVotingCheckpoint


```solidity
function _writeVotingCheckpoint() internal;
```

### _writeSupplyCheckpoint


```solidity
function _writeSupplyCheckpoint() internal;
```

### _bribeStart


```solidity
function _bribeStart(uint256 timestamp) internal pure returns (uint256);
```

### _safeTransfer


```solidity
function _safeTransfer(address token, address to, uint256 value) internal;
```

### _safeTransferFrom


```solidity
function _safeTransferFrom(address token, address from, address to, uint256 value) internal;
```

