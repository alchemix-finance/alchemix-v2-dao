# WeightedPool2TokensFactory
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/balancer/WeightedPool2TokensFactory.sol)


## Functions
### create


```solidity
function create(
    string memory name,
    string memory symbol,
    address[] memory tokens,
    uint256[] memory weights,
    uint256 swapFeePercentage,
    bool oracleEnabled,
    address owner
) external returns (address);
```

