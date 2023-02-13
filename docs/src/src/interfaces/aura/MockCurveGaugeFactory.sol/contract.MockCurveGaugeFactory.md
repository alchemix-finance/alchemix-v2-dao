# MockCurveGaugeFactory
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/aura/MockCurveGaugeFactory.sol)


## State Variables
### poolAddress

```solidity
address public poolAddress;
```


## Functions
### createMockPool


```solidity
function createMockPool(string calldata name, string calldata symbol, address lpToken, address[] calldata rewardTokens)
    external
    returns (address);
```

