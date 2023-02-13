# WeightedPoolUserData
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/balancer/WeightedPoolUserData.sol)


## Functions
### joinKind


```solidity
function joinKind(bytes memory self) internal pure returns (JoinKind);
```

### exitKind


```solidity
function exitKind(bytes memory self) internal pure returns (ExitKind);
```

### initialAmountsIn


```solidity
function initialAmountsIn(bytes memory self) internal pure returns (uint256[] memory amountsIn);
```

### exactTokensInForBptOut


```solidity
function exactTokensInForBptOut(bytes memory self)
    internal
    pure
    returns (uint256[] memory amountsIn, uint256 minBPTAmountOut);
```

### tokenInForExactBptOut


```solidity
function tokenInForExactBptOut(bytes memory self) internal pure returns (uint256 bptAmountOut, uint256 tokenIndex);
```

### allTokensInForExactBptOut


```solidity
function allTokensInForExactBptOut(bytes memory self) internal pure returns (uint256 bptAmountOut);
```

### exactBptInForTokenOut


```solidity
function exactBptInForTokenOut(bytes memory self) internal pure returns (uint256 bptAmountIn, uint256 tokenIndex);
```

### exactBptInForTokensOut


```solidity
function exactBptInForTokensOut(bytes memory self) internal pure returns (uint256 bptAmountIn);
```

### bptInForExactTokensOut


```solidity
function bptInForExactTokensOut(bytes memory self)
    internal
    pure
    returns (uint256[] memory amountsOut, uint256 maxBPTAmountIn);
```

## Enums
### JoinKind

```solidity
enum JoinKind {
    INIT,
    EXACT_TOKENS_IN_FOR_BPT_OUT,
    TOKEN_IN_FOR_EXACT_BPT_OUT,
    ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
}
```

### ExitKind

```solidity
enum ExitKind {
    EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
    EXACT_BPT_IN_FOR_TOKENS_OUT,
    BPT_IN_FOR_EXACT_TOKENS_OUT
}
```

