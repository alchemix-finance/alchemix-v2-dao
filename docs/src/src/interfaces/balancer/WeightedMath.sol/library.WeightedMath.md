# WeightedMath
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/balancer/WeightedMath.sol)


## State Variables
### _MIN_WEIGHT

```solidity
uint256 internal constant _MIN_WEIGHT = 0.01e18;
```


### _MAX_WEIGHTED_TOKENS

```solidity
uint256 internal constant _MAX_WEIGHTED_TOKENS = 100;
```


### _MAX_IN_RATIO

```solidity
uint256 internal constant _MAX_IN_RATIO = 0.3e18;
```


### _MAX_OUT_RATIO

```solidity
uint256 internal constant _MAX_OUT_RATIO = 0.3e18;
```


### _MAX_INVARIANT_RATIO

```solidity
uint256 internal constant _MAX_INVARIANT_RATIO = 3e18;
```


### _MIN_INVARIANT_RATIO

```solidity
uint256 internal constant _MIN_INVARIANT_RATIO = 0.7e18;
```


## Functions
### _calculateInvariant


```solidity
function _calculateInvariant(uint256[] memory normalizedWeights, uint256[] memory balances)
    internal
    pure
    returns (uint256 invariant);
```

### _calcOutGivenIn

// invariant               _____                                                             //
// wi = weight index i      | |      wi                                                      //
// bi = balance index i     | |  bi ^   = i                                                  //
// i = invariant                                                                             //


```solidity
function _calcOutGivenIn(uint256 balanceIn, uint256 weightIn, uint256 balanceOut, uint256 weightOut, uint256 amountIn)
    internal
    pure
    returns (uint256);
```

### _calcInGivenOut

// outGivenIn                                                                                //
// aO = amountOut                                                                            //
// bO = balanceOut                                                                           //
// bI = balanceIn              /      /            bI             \    (wI / wO) \           //
// aI = amountIn    aO = bO * |  1 - | --------------------------  | ^            |          //
// wI = weightIn               \      \       ( bI + aI )         /              /           //
// wO = weightOut                                                                            //


```solidity
function _calcInGivenOut(uint256 balanceIn, uint256 weightIn, uint256 balanceOut, uint256 weightOut, uint256 amountOut)
    internal
    pure
    returns (uint256);
```

### _calcBptOutGivenExactTokensIn

// inGivenOut                                                                                //
// aO = amountOut                                                                            //
// bO = balanceOut                                                                           //
// bI = balanceIn              /  /            bO             \    (wO / wI)      \          //
// aI = amountIn    aI = bI * |  | --------------------------  | ^            - 1  |         //
// wI = weightIn               \  \       ( bO - aO )         /                   /          //
// wO = weightOut                                                                            //


```solidity
function _calcBptOutGivenExactTokensIn(
    uint256[] memory balances,
    uint256[] memory normalizedWeights,
    uint256[] memory amountsIn,
    uint256 bptTotalSupply,
    uint256 swapFeePercentage
) internal pure returns (uint256);
```

### _calcBptOutGivenExactTokenIn


```solidity
function _calcBptOutGivenExactTokenIn(
    uint256 balance,
    uint256 normalizedWeight,
    uint256 amountIn,
    uint256 bptTotalSupply,
    uint256 swapFeePercentage
) internal pure returns (uint256);
```

### _computeJoinExactTokensInInvariantRatio

*Intermediate function to avoid stack-too-deep errors.*


```solidity
function _computeJoinExactTokensInInvariantRatio(
    uint256[] memory balances,
    uint256[] memory normalizedWeights,
    uint256[] memory amountsIn,
    uint256[] memory balanceRatiosWithFee,
    uint256 invariantRatioWithFees,
    uint256 swapFeePercentage
) private pure returns (uint256 invariantRatio);
```

### _calcTokenInGivenExactBptOut


```solidity
function _calcTokenInGivenExactBptOut(
    uint256 balance,
    uint256 normalizedWeight,
    uint256 bptAmountOut,
    uint256 bptTotalSupply,
    uint256 swapFeePercentage
) internal pure returns (uint256);
```

### _calcAllTokensInGivenExactBptOut

// tokenInForExactBPTOut                                                                 //
// a = amountIn                                                                          //
// b = balance                      /  /    totalBPT + bptOut      \    (1 / w)       \  //
// bptOut = bptAmountOut   a = b * |  | --------------------------  | ^          - 1  |  //
// bpt = totalBPT                   \  \       totalBPT            /                  /  //
// w = weight                                                                            //


```solidity
function _calcAllTokensInGivenExactBptOut(uint256[] memory balances, uint256 bptAmountOut, uint256 totalBPT)
    internal
    pure
    returns (uint256[] memory);
```

### _calcBptInGivenExactTokensOut

// tokensInForExactBptOut                                                          //
// (per token)                                                                     //
// aI = amountIn                   /   bptOut   \                                  //
// b = balance           aI = b * | ------------ |                                 //
// bptOut = bptAmountOut           \  totalBPT  /                                  //
// bpt = totalBPT                                                                  //


```solidity
function _calcBptInGivenExactTokensOut(
    uint256[] memory balances,
    uint256[] memory normalizedWeights,
    uint256[] memory amountsOut,
    uint256 bptTotalSupply,
    uint256 swapFeePercentage
) internal pure returns (uint256);
```

### _calcBptInGivenExactTokenOut


```solidity
function _calcBptInGivenExactTokenOut(
    uint256 balance,
    uint256 normalizedWeight,
    uint256 amountOut,
    uint256 bptTotalSupply,
    uint256 swapFeePercentage
) internal pure returns (uint256);
```

### _computeExitExactTokensOutInvariantRatio

*Intermediate function to avoid stack-too-deep errors.*


```solidity
function _computeExitExactTokensOutInvariantRatio(
    uint256[] memory balances,
    uint256[] memory normalizedWeights,
    uint256[] memory amountsOut,
    uint256[] memory balanceRatiosWithoutFee,
    uint256 invariantRatioWithoutFees,
    uint256 swapFeePercentage
) private pure returns (uint256 invariantRatio);
```

### _calcTokenOutGivenExactBptIn


```solidity
function _calcTokenOutGivenExactBptIn(
    uint256 balance,
    uint256 normalizedWeight,
    uint256 bptAmountIn,
    uint256 bptTotalSupply,
    uint256 swapFeePercentage
) internal pure returns (uint256);
```

### _calcTokensOutGivenExactBptIn

// exactBPTInForTokenOut                                                                //
// a = amountOut                                                                        //
// b = balance                     /      /    totalBPT - bptIn       \    (1 / w)  \   //
// bptIn = bptAmountIn    a = b * |  1 - | --------------------------  | ^           |  //
// bpt = totalBPT                  \      \       totalBPT            /             /   //
// w = weight                                                                           //


```solidity
function _calcTokensOutGivenExactBptIn(uint256[] memory balances, uint256 bptAmountIn, uint256 totalBPT)
    internal
    pure
    returns (uint256[] memory);
```

### _calcBptOutAddToken

// exactBPTInForTokensOut                                                                    //
// (per token)                                                                               //
// aO = amountOut                  /        bptIn         \                                  //
// b = balance           a0 = b * | ---------------------  |                                 //
// bptIn = bptAmountIn             \       totalBPT       /                                  //
// bpt = totalBPT                                                                            //

*Calculate the amount of BPT which should be minted when adding a new token to the Pool.
Note that normalizedWeight is set that it corresponds to the desired weight of this token *after* adding it.
i.e. For a two token 50:50 pool which we want to turn into a 33:33:33 pool, we use a normalized weight of 33%*


```solidity
function _calcBptOutAddToken(uint256 totalSupply, uint256 normalizedWeight) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`totalSupply`|`uint256`|- the total supply of the Pool's BPT.|
|`normalizedWeight`|`uint256`|- the normalized weight of the token to be added (normalized relative to final weights)|


