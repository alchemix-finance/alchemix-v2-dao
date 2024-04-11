# Minter
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/Minter.sol)

**Inherits:**
[IMinter](/src/interfaces/IMinter.sol/interface.IMinter.md)

Contract to handle ALCX emissions and their distriubtion


## State Variables
### DURATION

```solidity
uint256 public immutable DURATION = 2 weeks;
```


### BPS

```solidity
uint256 public immutable BPS = 10_000;
```


### TAIL_EMISSIONS_RATE

```solidity
uint256 public constant TAIL_EMISSIONS_RATE = 2194e18;
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


### treasuryEmissionsRate

```solidity
uint256 public treasuryEmissionsRate;
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


### treasury

```solidity
address public treasury;
```


### alcx

```solidity
IAlchemixToken public immutable alcx;
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


### calculateEmissions

Calculate the amount of emissions to be distributed


```solidity
function calculateEmissions(uint256 _emissions, uint256 _rate) public pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_emissions`|`uint256`| Amount of emissions to be minted for an epoch|
|`_rate`|`uint256`|   Rate of emissions to be distributed|

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

### setTreasury


```solidity
function setTreasury(address _treasury) external;
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


