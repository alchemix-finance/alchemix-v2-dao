# MockCurveGaugeFactory
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/aura/MockCurveGaugeFactory.sol)


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

