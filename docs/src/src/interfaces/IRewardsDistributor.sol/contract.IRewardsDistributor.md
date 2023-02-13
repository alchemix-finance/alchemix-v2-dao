# IRewardsDistributor
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/IRewardsDistributor.sol)


## Functions
### checkpointToken


```solidity
function checkpointToken() external;
```

### checkpointTotalSupply


```solidity
function checkpointTotalSupply() external;
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
function amountToCompound(uint256 _alcxAmount) external view returns (uint256, uint256[] memory);
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


### claim

Claim ALCX rewards for a given veALCX position


```solidity
function claim(uint256 _tokenId, bool _compound) external payable returns (uint256);
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


## Events
### CheckpointToken
Emitted when a checkpoint is recorded


```solidity
event CheckpointToken(uint256 time, uint256 tokens);
```

### Claimed
Emitted when veALCX rewards are claimed


```solidity
event Claimed(uint256 tokenId, uint256 amount, uint256 claimEpoch, uint256 maxEpoch);
```

