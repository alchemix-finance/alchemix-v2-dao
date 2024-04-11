# WeightedPool2TokensFactory
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/balancer/WeightedPool2TokensFactory.sol)


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

