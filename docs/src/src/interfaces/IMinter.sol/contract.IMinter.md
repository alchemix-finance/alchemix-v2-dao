# IMinter
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/IMinter.sol)


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


### calculateGrowth

Governance-defined portion of emissions sent to veALCX stakers


```solidity
function calculateGrowth(uint256 _minted) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_minted`|`uint256`| Amount of emissions to be minted for an epoch|

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


## Events
### Mint
Emitted when emissions are minted


```solidity
event Mint(address indexed sender, uint256 epochEmissions, uint256 circulatingEmissions);
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
    uint256 supply;
    uint256 rewards;
    uint256 stepdown;
}
```

