# IMinter
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/IMinter.sol)


## Functions
### setVeAlcxEmissionsRate

Sets the emissions rate of rewards sent to veALCX stakers


```solidity
function setVeAlcxEmissionsRate(uint256 _veAlcxEmissionsRate) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_veAlcxEmissionsRate`|`uint256`|The rate in BPS|


### epochEmission

Returns the amount of emissions


```solidity
function epochEmission() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Amount of emissions for current epoch|


### circulatingEmissionsSupply

Returns the amount of emissions in circulation


```solidity
function circulatingEmissionsSupply() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Amount of emissions in circulation|


### calculateEmissions

Calculate the amount of emissions to be distributed


```solidity
function calculateEmissions(uint256 _emissions, uint256 _rate) external view returns (uint256);
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


### activePeriod


```solidity
function activePeriod() external view returns (uint256);
```

### DURATION


```solidity
function DURATION() external view returns (uint256);
```

## Events
### AdminUpdated
Emitted when admin is updated


```solidity
event AdminUpdated(address newAdmin);
```

### Mint
Emitted when emissions are minted


```solidity
event Mint(address indexed sender, uint256 epochEmissions, uint256 circulatingEmissions);
```

### SetVeAlcxEmissionsRate
Emitted when emissions rate is updated


```solidity
event SetVeAlcxEmissionsRate(uint256 veAlcxEmissionsRate);
```

### TreasuryUpdated
Emitted when treasury address is updated


```solidity
event TreasuryUpdated(address treasury);
```

## Structs
### InitializationParams
*Data to initialize the minter based on current emissions*


```solidity
struct InitializationParams {
    address alcx;
    address voter;
    address ve;
    address rewardsDistributor;
    address revenueHandler;
    address timeGauge;
    address treasury;
    uint256 supply;
    uint256 rewards;
    uint256 stepdown;
}
```

