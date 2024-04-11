# IPoolAdapter
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/IPoolAdapter.sol)


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

