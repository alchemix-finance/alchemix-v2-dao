# IVoter
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/IVoter.sol)


## Functions
### veALCX


```solidity
function veALCX() external view returns (address);
```

### admin


```solidity
function admin() external view returns (address);
```

### emergencyCouncil


```solidity
function emergencyCouncil() external view returns (address);
```

### maxVotingPower

Get the maximum voting power a given veALCX can have by using FLUX


```solidity
function maxVotingPower(uint256 _tokenId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Maximum voting power|


### maxFluxBoost

Get the maximum amount of flux a given veALCX could use as a boost


```solidity
function maxFluxBoost(uint256 _tokenId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Maximum flux amount|


### setBoostMultiplier

Set the max veALCX voting power can be boosted by with flux

*Can only be called by the admin*


```solidity
function setBoostMultiplier(uint256 _boostMultiplier) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_boostMultiplier`|`uint256`|BPS of boost|


### reset

Reset the voting status of a veALCX

*Can only be called by the an approved address or the veALCX owner*

*Accrues any unused flux*


```solidity
function reset(uint256 _tokenId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token to reset|


### poke

Update the voting status of a veALCX to maintain the same voting status

*Accrues any unused flux*


```solidity
function poke(uint256 _tokenId, uint256 _boost) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token to poke|
|`_boost`|`uint256`|  Amount of flux to boost vote by|


### vote

Vote on one or multiple pools for a single veALCX

*Can only be called once per epoch. Accrues any unused flux*


```solidity
function vote(uint256 _tokenId, address[] calldata _poolVote, uint256[] calldata _weights, uint256 _boost) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`| ID of the token voting|
|`_poolVote`|`address[]`|Array of the pools being voted|
|`_weights`|`uint256[]`| Weights of the pools|
|`_boost`|`uint256`|   Amount of flux to boost vote by|


### createGauge

Creates a gauge for a pool

*Index and receiver are votium specific parameters and should be 0 and 0xdead for other gauge types*


```solidity
function createGauge(address _pool, GaugeType _gaugeType) external returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_pool`|`address`|     Address of the pool the gauge is for|
|`_gaugeType`|`GaugeType`|Type of gauge being created|


### attachTokenToGauge

Attach veALCX token to a gauge

*Can only be called by an active gauge*


```solidity
function attachTokenToGauge(uint256 _tokenId, address account) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token being attached|
|`account`|`address`| Address of owner|


### detachTokenFromGauge

Detach veALCX token to a gauge

*Can only be called by a gauge*


```solidity
function detachTokenFromGauge(uint256 _tokenId, address account) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token being detached|
|`account`|`address`| Address of owner|


### notifyRewardAmount

Send the distribution of emissions to the Voter contract


```solidity
function notifyRewardAmount(uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount of rewards being distributed|


### distribute

Distribute rewards and bribes to a given gauge


```solidity
function distribute(address _gauge) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_gauge`|`address`|Address of gauge receiving rewards and bribes|


## Events
### GaugeCreated

```solidity
event GaugeCreated(address indexed gauge, address creator, address indexed bribe, address indexed pool);
```

### GaugeKilled

```solidity
event GaugeKilled(address indexed gauge);
```

### GaugeRevived

```solidity
event GaugeRevived(address indexed gauge);
```

### Voted

```solidity
event Voted(address indexed voter, uint256 tokenId, uint256 weight);
```

### Abstained

```solidity
event Abstained(uint256 tokenId, uint256 weight);
```

### Deposit

```solidity
event Deposit(address indexed account, address indexed gauge, uint256 tokenId, uint256 amount);
```

### Withdraw

```solidity
event Withdraw(address indexed account, address indexed gauge, uint256 tokenId, uint256 amount);
```

### NotifyReward

```solidity
event NotifyReward(address indexed sender, address indexed reward, uint256 amount);
```

### DistributeReward

```solidity
event DistributeReward(address indexed sender, address indexed gauge, uint256 amount);
```

### Attach

```solidity
event Attach(address indexed owner, address indexed gauge, uint256 tokenId);
```

### Detach

```solidity
event Detach(address indexed owner, address indexed gauge, uint256 tokenId);
```

### Whitelisted

```solidity
event Whitelisted(address indexed whitelister, address indexed token);
```

## Enums
### GaugeType

```solidity
enum GaugeType {
    Staking,
    Passthrough,
    Curve
}
```

