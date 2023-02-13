# IPoolAdapter
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/IPoolAdapter.sol)


## Functions
### pool


```solidity
function pool() external view returns (address);
```

### getDy


```solidity
function getDy(address inputToken, address outputToken, uint256 inputAmount) external view returns (uint256);
```

### melt


```solidity
function melt(address inputToken, address outputToken, uint256 inputAmount, uint256 minimumAmountOut)
    external
    returns (uint256);
```

