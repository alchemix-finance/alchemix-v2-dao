# IExternalWeightedMath
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/balancer/IExternalWeightedMath.sol)

Interface for ExternalWeightedMath, a contract-wrapper for Weighted Math, Joins and Exits.


## Functions
### calculateInvariant

*See `WeightedMath._calculateInvariant`.*


```solidity
function calculateInvariant(uint256[] memory normalizedWeights, uint256[] memory balances)
    external
    pure
    returns (uint256);
```

### calcOutGivenIn

*See `WeightedMath._calcOutGivenIn`.*


```solidity
function calcOutGivenIn(uint256 balanceIn, uint256 weightIn, uint256 balanceOut, uint256 weightOut, uint256 amountIn)
    external
    pure
    returns (uint256);
```

### calcInGivenOut

*See `WeightedMath._calcInGivenOut`.*


```solidity
function calcInGivenOut(uint256 balanceIn, uint256 weightIn, uint256 balanceOut, uint256 weightOut, uint256 amountOut)
    external
    pure
    returns (uint256);
```

### calcBptOutGivenExactTokensIn

*See `WeightedMath._calcBptOutGivenExactTokensIn`.*


```solidity
function calcBptOutGivenExactTokensIn(
    uint256[] memory balances,
    uint256[] memory normalizedWeights,
    uint256[] memory amountsIn,
    uint256 bptTotalSupply,
    uint256 swapFeePercentage
) external pure returns (uint256);
```

### calcBptOutGivenExactTokenIn

*See `WeightedMath._calcBptOutGivenExactTokenIn`.*


```solidity
function calcBptOutGivenExactTokenIn(
    uint256 balance,
    uint256 normalizedWeight,
    uint256 amountIn,
    uint256 bptTotalSupply,
    uint256 swapFeePercentage
) external pure returns (uint256);
```

### calcTokenInGivenExactBptOut

*See `WeightedMath._calcTokenInGivenExactBptOut`.*


```solidity
function calcTokenInGivenExactBptOut(
    uint256 balance,
    uint256 normalizedWeight,
    uint256 bptAmountOut,
    uint256 bptTotalSupply,
    uint256 swapFeePercentage
) external pure returns (uint256);
```

### calcAllTokensInGivenExactBptOut

*See `WeightedMath._calcAllTokensInGivenExactBptOut`.*


```solidity
function calcAllTokensInGivenExactBptOut(uint256[] memory balances, uint256 bptAmountOut, uint256 totalBPT)
    external
    pure
    returns (uint256[] memory);
```

### calcBptInGivenExactTokensOut

*See `WeightedMath._calcBptInGivenExactTokensOut`.*


```solidity
function calcBptInGivenExactTokensOut(
    uint256[] memory balances,
    uint256[] memory normalizedWeights,
    uint256[] memory amountsOut,
    uint256 bptTotalSupply,
    uint256 swapFeePercentage
) external pure returns (uint256);
```

### calcBptInGivenExactTokenOut

*See `WeightedMath._calcBptInGivenExactTokenOut`.*


```solidity
function calcBptInGivenExactTokenOut(
    uint256 balance,
    uint256 normalizedWeight,
    uint256 amountOut,
    uint256 bptTotalSupply,
    uint256 swapFeePercentage
) external pure returns (uint256);
```

### calcTokenOutGivenExactBptIn

*See `WeightedMath._calcTokenOutGivenExactBptIn`.*


```solidity
function calcTokenOutGivenExactBptIn(
    uint256 balance,
    uint256 normalizedWeight,
    uint256 bptAmountIn,
    uint256 bptTotalSupply,
    uint256 swapFeePercentage
) external pure returns (uint256);
```

### calcTokensOutGivenExactBptIn

*See `WeightedMath._calcTokensOutGivenExactBptIn`.*


```solidity
function calcTokensOutGivenExactBptIn(uint256[] memory balances, uint256 bptAmountIn, uint256 totalBPT)
    external
    pure
    returns (uint256[] memory);
```

### calcBptOutAddToken

*See `WeightedMath._calcBptOutAddToken`.*


```solidity
function calcBptOutAddToken(uint256 totalSupply, uint256 normalizedWeight) external pure returns (uint256);
```

### joinExactTokensInForBPTOut

*See `WeightedJoinsLib.joinExactTokensInForBPTOut`.*


```solidity
function joinExactTokensInForBPTOut(
    uint256[] memory balances,
    uint256[] memory normalizedWeights,
    uint256[] memory scalingFactors,
    uint256 totalSupply,
    uint256 swapFeePercentage,
    bytes memory userData
) external pure returns (uint256, uint256[] memory);
```

### joinTokenInForExactBPTOut

*See `WeightedJoinsLib.joinTokenInForExactBPTOut`.*


```solidity
function joinTokenInForExactBPTOut(
    uint256[] memory balances,
    uint256[] memory normalizedWeights,
    uint256 totalSupply,
    uint256 swapFeePercentage,
    bytes memory userData
) external pure returns (uint256, uint256[] memory);
```

### joinAllTokensInForExactBPTOut

*See `WeightedJoinsLib.joinAllTokensInForExactBPTOut`.*


```solidity
function joinAllTokensInForExactBPTOut(uint256[] memory balances, uint256 totalSupply, bytes memory userData)
    external
    pure
    returns (uint256 bptAmountOut, uint256[] memory amountsIn);
```

### exitExactBPTInForTokenOut

*See `WeightedExitsLib.exitExactBPTInForTokenOut`.*


```solidity
function exitExactBPTInForTokenOut(
    uint256[] memory balances,
    uint256[] memory normalizedWeights,
    uint256 totalSupply,
    uint256 swapFeePercentage,
    bytes memory userData
) external pure returns (uint256, uint256[] memory);
```

### exitExactBPTInForTokensOut

*See `WeightedExitsLib.exitExactBPTInForTokensOut`.*


```solidity
function exitExactBPTInForTokensOut(uint256[] memory balances, uint256 totalSupply, bytes memory userData)
    external
    pure
    returns (uint256 bptAmountIn, uint256[] memory amountsOut);
```

### exitBPTInForExactTokensOut

*See `WeightedExitsLib.exitBPTInForExactTokensOut`.*


```solidity
function exitBPTInForExactTokensOut(
    uint256[] memory balances,
    uint256[] memory normalizedWeights,
    uint256[] memory scalingFactors,
    uint256 totalSupply,
    uint256 swapFeePercentage,
    bytes memory userData
) external pure returns (uint256, uint256[] memory);
```

