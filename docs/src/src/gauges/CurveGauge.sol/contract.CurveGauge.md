# CurveGauge
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/gauges/CurveGauge.sol)

**Inherits:**
[BaseGauge](/src/BaseGauge.sol/abstract.BaseGauge.md)

Gauge to handle distribution of rewards to a given Curve pool via Votium

*Pool index is subject to change and proposal id is located in the snapshot url*


## State Variables
### poolIndex

```solidity
uint256 poolIndex;
```


### proposal

```solidity
bytes32 proposal;
```


### proposalUpdated

```solidity
bool proposalUpdated;
```


### initialized

```solidity
bool initialized;
```


## Functions
### constructor


```solidity
constructor(address _bribe, address _ve, address _voter);
```

### initialize

Initialize curve gauge specific variables


```solidity
function initialize(uint256 _poolIndex, address _receiver) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_poolIndex`|`uint256`|Index of pool on votium|
|`_receiver`|`address`|Votium contract that is sent rewards|


### updateIndex

Update the pool index

*Pool index on votium subject to change*


```solidity
function updateIndex(uint256 _poolIndex) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_poolIndex`|`uint256`|New pool index|


### updateProposal

Set the proposal id

*Proposal id must be set manually every epoch*


```solidity
function updateProposal(bytes32 _proposal) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_proposal`|`bytes32`|Proposal id from snapshot url|


### _passthroughRewards

Pass rewards to votium contract


```solidity
function _passthroughRewards(uint256 _amount) internal override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Amount of rewards|


## Events
### ProposalUpdated

```solidity
event ProposalUpdated(bytes32 indexed newProposal, bool proposalUpdated);
```

### IndexUpdated

```solidity
event IndexUpdated(uint256 indexed newIndex);
```

### Initialized

```solidity
event Initialized(uint256 poolIndex, address receiver, bool initialized);
```

