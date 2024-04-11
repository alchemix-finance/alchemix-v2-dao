# Voter
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/Voter.sol)

**Inherits:**
[IVoter](/src/interfaces/IVoter.sol/interface.IVoter.md)

Voting contract to handle veALCX gauge voting


## State Variables
### base

```solidity
address internal immutable base;
```


### veALCX

```solidity
address public immutable veALCX;
```


### FLUX

```solidity
address public immutable FLUX;
```


### gaugefactory

```solidity
address public immutable gaugefactory;
```


### bribefactory

```solidity
address public immutable bribefactory;
```


### BPS

```solidity
uint256 internal constant BPS = 10_000;
```


### MAX_BOOST

```solidity
uint256 internal constant MAX_BOOST = 5000;
```


### MIN_BOOST

```solidity
uint256 internal constant MIN_BOOST = 0;
```


### DURATION

```solidity
uint256 internal constant DURATION = 7 days;
```


### BRIBE_LAG

```solidity
uint256 internal constant BRIBE_LAG = 1 days;
```


### index

```solidity
uint256 internal index;
```


### minter

```solidity
address public minter;
```


### admin

```solidity
address public admin;
```


### pendingAdmin

```solidity
address public pendingAdmin;
```


### emergencyCouncil

```solidity
address public emergencyCouncil;
```


### totalWeight

```solidity
uint256 public totalWeight;
```


### boostMultiplier

```solidity
uint256 public boostMultiplier = 10000;
```


### pools

```solidity
address[] public pools;
```


### gauges

```solidity
mapping(address => address) public gauges;
```


### poolForGauge

```solidity
mapping(address => address) public poolForGauge;
```


### bribes

```solidity
mapping(address => address) public bribes;
```


### weights

```solidity
mapping(address => uint256) public weights;
```


### votes

```solidity
mapping(uint256 => mapping(address => uint256)) public votes;
```


### poolVote

```solidity
mapping(uint256 => address[]) public poolVote;
```


### usedWeights

```solidity
mapping(uint256 => uint256) public usedWeights;
```


### lastVoted

```solidity
mapping(uint256 => uint256) public lastVoted;
```


### isGauge

```solidity
mapping(address => bool) public isGauge;
```


### isWhitelisted

```solidity
mapping(address => bool) public isWhitelisted;
```


### isAlive

```solidity
mapping(address => bool) public isAlive;
```


### supplyIndex

```solidity
mapping(address => uint256) internal supplyIndex;
```


### claimable

```solidity
mapping(address => uint256) public claimable;
```


### _unlocked

```solidity
uint256 internal _unlocked = 1;
```


## Functions
### constructor


```solidity
constructor(address _ve, address _gauges, address _bribes, address _flux, address _token);
```

### lock


```solidity
modifier lock();
```

### onlyNewEpoch


```solidity
modifier onlyNewEpoch(uint256 _tokenId);
```

### maxVotingPower

Get the maximum voting power a given veALCX can have by using FLUX


```solidity
function maxVotingPower(uint256 _tokenId) public view returns (uint256);
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


### length


```solidity
function length() external view returns (uint256);
```

### getPoolVote


```solidity
function getPoolVote(uint256 _tokenId) external view returns (address[] memory);
```

### setMinter


```solidity
function setMinter(address _minter) external;
```

### setAdmin


```solidity
function setAdmin(address _admin) external;
```

### acceptAdmin


```solidity
function acceptAdmin() external;
```

### setEmergencyCouncil


```solidity
function setEmergencyCouncil(address _council) public;
```

### swapReward


```solidity
function swapReward(address gaugeAddress, uint256 tokenIndex, address oldToken, address newToken) external;
```

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


```solidity
function reset(uint256 _tokenId) public onlyNewEpoch(_tokenId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token to reset|


### poke

Update the voting status of a veALCX to maintain the same voting status

*Accrues any unused flux*


```solidity
function poke(uint256 _tokenId) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token to poke|


### pokeTokens

Update the voting status of multiple veALCXs to maintain the same voting status

*Resets tokens that have expired*


```solidity
function pokeTokens(uint256[] memory _tokenIds) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenIds`|`uint256[]`|Array of token IDs to poke|


### vote

Vote on one or multiple pools for a single veALCX

*Can only be called once per epoch. Accrues any unused flux*


```solidity
function vote(uint256 _tokenId, address[] calldata _poolVote, uint256[] calldata _weights, uint256 _boost)
    external
    onlyNewEpoch(_tokenId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`| ID of the token voting|
|`_poolVote`|`address[]`|Array of the pools being voted|
|`_weights`|`uint256[]`| Weights of the pools|
|`_boost`|`uint256`|   Amount of flux to boost vote by|


### whitelist

Whitelist a token to be a permitted bribe token


```solidity
function whitelist(address _token) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token`|`address`|address of the token|


### removeFromWhitelist

Remove a token from the whitelist


```solidity
function removeFromWhitelist(address _token) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token`|`address`|address of the token|


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


### killGauge


```solidity
function killGauge(address _gauge) external;
```

### reviveGauge


```solidity
function reviveGauge(address _gauge) external;
```

### attachTokenToGauge

Attach veALCX token to a gauge

*Can only be called by an active gauge*


```solidity
function attachTokenToGauge(uint256 tokenId, address account) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`||
|`account`|`address`| Address of owner|


### detachTokenFromGauge

Detach veALCX token to a gauge

*Can only be called by a gauge*


```solidity
function detachTokenFromGauge(uint256 tokenId, address account) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`||
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


### updateFor


```solidity
function updateFor(address[] memory _gauges) external;
```

### updateForRange


```solidity
function updateForRange(uint256 start, uint256 end) public;
```

### updateAll


```solidity
function updateAll() external;
```

### updateGauge


```solidity
function updateGauge(address _gauge) external;
```

### claimBribes


```solidity
function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint256 _tokenId) external;
```

### distribute

Distribute rewards and bribes to all gauges


```solidity
function distribute() external;
```

### _distribute


```solidity
function _distribute(address _gauge) internal;
```

### _reset


```solidity
function _reset(uint256 _tokenId) internal;
```

### _vote


```solidity
function _vote(uint256 _tokenId, address[] memory _poolVote, uint256[] memory _weights, uint256 _boost) internal;
```

### _whitelist


```solidity
function _whitelist(address _token) internal;
```

### _removeFromWhitelist


```solidity
function _removeFromWhitelist(address _token) internal;
```

### _updateFor


```solidity
function _updateFor(address _gauge) internal;
```

### _safeTransferFrom


```solidity
function _safeTransferFrom(address token, address from, address to, uint256 value) internal;
```

