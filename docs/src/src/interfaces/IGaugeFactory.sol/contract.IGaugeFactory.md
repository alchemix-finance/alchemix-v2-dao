# IGaugeFactory
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/IGaugeFactory.sol)


## Functions
### admin


```solidity
function admin() external view returns (address);
```

### createStakingGauge


```solidity
function createStakingGauge(address, address, address) external returns (address);
```

### createCurveGauge


```solidity
function createCurveGauge(address, address) external returns (address);
```

### createPassthroughGauge


```solidity
function createPassthroughGauge(address, address, address) external returns (address);
```

