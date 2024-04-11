# IPoolSwapStructs
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/balancer/IPoolSwapStructs.sol)


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

