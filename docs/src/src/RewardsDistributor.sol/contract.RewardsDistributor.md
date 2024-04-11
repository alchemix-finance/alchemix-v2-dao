# RewardsDistributor
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/RewardsDistributor.sol)

**Inherits:**
[IRewardsDistributor](/src/interfaces/IRewardsDistributor.sol/interface.IRewardsDistributor.md), ReentrancyGuard

Contract to facilitate distribution of rewards to veALCX holders


## State Variables
### WEEK

```solidity
uint256 public immutable WEEK = 1 weeks;
```


### BURN_ADDRESS

```solidity
address public immutable BURN_ADDRESS = address(0);
```


### BPS

```solidity
uint256 public immutable BPS = 10_000;
```


### balancerPoolId

```solidity
bytes32 public balancerPoolId;
```


### startTime

```solidity
uint256 public startTime;
```


### timeCursor

```solidity
uint256 public timeCursor;
```


### lastTokenTime

```solidity
uint256 public lastTokenTime;
```


### tokenLastBalance

```solidity
uint256 public tokenLastBalance;
```


### votingEscrow

```solidity
address public immutable votingEscrow;
```


### rewardsToken

```solidity
address public rewardsToken;
```


### lockedToken

```solidity
address public lockedToken;
```


### depositor

```solidity
address public depositor;
```


### veSupply

```solidity
uint256[1000000000000000] public veSupply;
```


### tokensPerWeek

```solidity
uint256[1000000000000000] public tokensPerWeek;
```


### timeCursorOf

```solidity
mapping(uint256 => uint256) public timeCursorOf;
```


### userEpochOf

```solidity
mapping(uint256 => uint256) public userEpochOf;
```


### WETH

```solidity
IWETH9 public immutable WETH;
```


### balancerVault

```solidity
IVault public immutable balancerVault;
```


### balancerPool

```solidity
IBasePool public immutable balancerPool;
```


### priceFeed

```solidity
AggregatorV3Interface public priceFeed;
```


### poolAssets

```solidity
IAsset[] public poolAssets = new IAsset[](2);
```


## Functions
### constructor


```solidity
constructor(address _votingEscrow, address _weth, address _balancerVault, address _priceFeed);
```

### receive

*Allows for payments from the WETH contract.*


```solidity
receive() external payable;
```

### getBalancerInfo

Get the balancer pool ID, address, and vault address


```solidity
function getBalancerInfo() external view returns (bytes32, address, address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|Balancer pool ID|
|`<none>`|`address`||
|`<none>`|`address`||


### timestamp


```solidity
function timestamp() external view returns (uint256);
```

### claimable

Amount of ALCX available to be claimed for a veALCX position


```solidity
function claimable(uint256 _tokenId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Amount of ALCX claimable|


### amountToCompound

Get the amount of ETH or WETH required to create balanced pool deposit


```solidity
function amountToCompound(uint256 _alcxAmount) public view returns (uint256, uint256[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_alcxAmount`|`uint256`|Amount of ALCX that will make up the balanced deposit|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Amount of ETH or WETH|
|`<none>`|`uint256[]`|uint256[] Normalized weights of the pool. Prevents an additional lookup of weights|


### checkpointToken




```solidity
function checkpointToken() external;
```

### checkpointTotalSupply


```solidity
function checkpointTotalSupply() external;
```

### claim

Claim ALCX rewards for a given veALCX position


```solidity
function claim(uint256 _tokenId, bool _compound) external payable nonReentrant returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token|
|`_compound`|`bool`|Indicator that determines if rewards are being compounded|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Amount of ALCX that was either claimed or compounded|


### setDepositor

*Once off event on contract initialize*


```solidity
function setDepositor(address _depositor) external;
```

### _checkpointToken

Record data to checkpoint

*Records veALCX holder rewards over time*


```solidity
function _checkpointToken() internal;
```

### _findTimestampEpoch


```solidity
function _findTimestampEpoch(address ve, uint256 _timestamp) internal view returns (uint256);
```

### _findTimestampUserEpoch


```solidity
function _findTimestampUserEpoch(address ve, uint256 tokenId, uint256 _timestamp, uint256 maxUserEpoch)
    internal
    view
    returns (uint256);
```

### _checkpointTotalSupply

Record global data to a checkpoint


```solidity
function _checkpointTotalSupply() internal;
```

### _claim

Get the amount of ALCX rewards a veALCX has earned


```solidity
function _claim(uint256 _tokenId, address _ve, uint256 _lastTokenTime) internal returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token|
|`_ve`|`address`|veALCX address|
|`_lastTokenTime`|`uint256`|Point in time of veALCX rewards accrual|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Amount of ALCX rewards claimable|


### _claimable


```solidity
function _claimable(uint256 _tokenId, address _ve, uint256 _lastTokenTime)
    internal
    view
    returns (uint256, uint256, uint256, uint256);
```

### _depositIntoBalancerPool

Claim ALCX rewards for a given veALCX position


```solidity
function _depositIntoBalancerPool(uint256 _wethAmount, uint256 _alcxAmount, uint256[] memory _normalizedWeights)
    internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_wethAmount`|`uint256`|Amount of WETH to deposit into pool|
|`_alcxAmount`|`uint256`|Amount of ALCX to deposit into pool|
|`_normalizedWeights`|`uint256[]`|Weight of ALCX and WETH|


