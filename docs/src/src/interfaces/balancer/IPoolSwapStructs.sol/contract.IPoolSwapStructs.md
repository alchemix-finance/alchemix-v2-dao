# IPoolSwapStructs
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/balancer/IPoolSwapStructs.sol)


## Structs
### SwapRequest

```solidity
struct SwapRequest {
    IVault.SwapKind kind;
    IERC20 tokenIn;
    IERC20 tokenOut;
    uint256 amount;
    bytes32 poolId;
    uint256 lastChangeBlock;
    address from;
    address to;
    bytes userData;
}
```

