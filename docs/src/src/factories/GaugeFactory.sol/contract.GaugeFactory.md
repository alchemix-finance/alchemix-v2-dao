# GaugeFactory
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/factories/GaugeFactory.sol)


## State Variables
### lastGauge

```solidity
address public lastGauge;
```


## Functions
### createStakingGauge


```solidity
function createStakingGauge(address _pool, address _bribe, address _ve) external returns (address);
```

### createCurveGauge


```solidity
function createCurveGauge(address _bribe, address _ve) external returns (address);
```

### createPassthroughGauge


```solidity
function createPassthroughGauge(address _receiver, address _bribe, address _ve) external returns (address);
```

