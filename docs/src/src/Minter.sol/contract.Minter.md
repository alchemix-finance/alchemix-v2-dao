# Minter
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/Minter.sol)

**Inherits:**
[IMinter](/src/interfaces/IMinter.sol/contract.IMinter.md)

Contract to handle ALCX emissions and their distriubtion


## State Variables
### WEEK

```solidity
uint256 public constant WEEK = 86400 * 7;
```


### TAIL_EMISSIONS_RATE

```solidity
uint256 public constant TAIL_EMISSIONS_RATE = 2194e18;
```


### BPS

```solidity
uint256 public constant BPS = 10000;
```


### epochEmissions

```solidity
uint256 public epochEmissions;
```


### activePeriod

```solidity
uint256 public activePeriod;
```


### stepdown

```solidity
uint256 public stepdown;
```


### rewards

```solidity
uint256 public rewards;
```


### supply

```solidity
uint256 public supply;
```


### veAlcxEmissionsRate

```solidity
uint256 public veAlcxEmissionsRate;
```


### timeEmissionsRate

```solidity
uint256 public timeEmissionsRate;
```


### admin

```solidity
address public admin;
```


### pendingAdmin

```solidity
address public pendingAdmin;
```


### initializer

```solidity
address public initializer;
```


### initialized

```solidity
bool public initialized;
```


### alcx

```solidity
IAlchemixToken public alcx;
```


### voter

```solidity
IVoter public immutable voter;
```


### ve

```solidity
IVotingEscrow public immutable ve;
```


### rewardsDistributor

```solidity
IRewardsDistributor public immutable rewardsDistributor;
```


### revenueHandler

```solidity
IRevenueHandler public immutable revenueHandler;
```


### timeGauge

```solidity
IStakingRewards public immutable timeGauge;
```


## Functions
### constructor


```solidity
constructor(InitializationParams memory params);
```

### epochEmission

Returns the amount of emissions


```solidity
function epochEmission() public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Amount of emissions for current epoch|


### circulatingEmissionsSupply

Returns the amount of emissions in circulation


```solidity
function circulatingEmissionsSupply() public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Amount of emissions in circulation|


### calculateGrowth

Governance-defined portion of emissions sent to veALCX stakers


```solidity
function calculateGrowth(uint256 _minted) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_minted`|`uint256`| Amount of emissions to be minted for an epoch|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Amount of emissions distributed to veALCX stakers|


### initialize


```solidity
function initialize() external;
```

### setAdmin


```solidity
function setAdmin(address _admin) external;
```

### acceptAdmin


```solidity
function acceptAdmin() external;
```

### setVeAlcxEmissionsRate

Sets the emissions rate of rewards sent to veALCX stakers


```solidity
function setVeAlcxEmissionsRate(uint256 _veAlcxEmissionsRate) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_veAlcxEmissionsRate`|`uint256`|The rate in BPS|


### updatePeriod

Updates the epoch, mints new emissions, sends emissions to rewards distributor and voter

*Can only be called once per epoch*


```solidity
function updatePeriod() external returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 The current period|


