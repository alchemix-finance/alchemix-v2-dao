# IManagedPool
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/balancer/IManagedPool.sol)

**Inherits:**
[IBasePool](/src/interfaces/balancer/IBasePool.sol/interface.IBasePool.md)


## Functions
### getActualSupply

Returns the effective BPT supply.

*The Pool owes debt to the Protocol and the Pool's owner in the form of unminted BPT, which will be minted
immediately before the next join or exit. We need to take these into account since, even if they don't yet exist,
they will effectively be included in any Pool operation that involves BPT.
In the vast majority of cases, this function should be used instead of `totalSupply()`.*


```solidity
function getActualSupply() external view returns (uint256);
```

### updateSwapFeeGradually

Schedule a gradual swap fee update.

*The swap fee will change from the given starting value (which may or may not be the current
value) to the given ending fee percentage, over startTime to endTime.
Note that calling this with a starting swap fee different from the current value will immediately change the
current swap fee to `startSwapFeePercentage`, before commencing the gradual change at `startTime`.
Emits the GradualSwapFeeUpdateScheduled event.
This is a permissioned function.*


```solidity
function updateSwapFeeGradually(
    uint256 startTime,
    uint256 endTime,
    uint256 startSwapFeePercentage,
    uint256 endSwapFeePercentage
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`startTime`|`uint256`|- The timestamp when the swap fee change will begin.|
|`endTime`|`uint256`|- The timestamp when the swap fee change will end (must be >= startTime).|
|`startSwapFeePercentage`|`uint256`|- The starting value for the swap fee change.|
|`endSwapFeePercentage`|`uint256`|- The ending value for the swap fee change. If the current timestamp >= endTime, `getSwapFeePercentage()` will return this value.|


### getGradualSwapFeeUpdateParams

Returns the current gradual swap fee update parameters.

*The current swap fee can be retrieved via `getSwapFeePercentage()`.*


```solidity
function getGradualSwapFeeUpdateParams()
    external
    view
    returns (uint256 startTime, uint256 endTime, uint256 startSwapFeePercentage, uint256 endSwapFeePercentage);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`startTime`|`uint256`|- The timestamp when the swap fee update will begin.|
|`endTime`|`uint256`|- The timestamp when the swap fee update will end.|
|`startSwapFeePercentage`|`uint256`|- The starting swap fee percentage (could be different from the current value).|
|`endSwapFeePercentage`|`uint256`|- The final swap fee percentage, when the current timestamp >= endTime.|


### updateWeightsGradually

Schedule a gradual weight change.

*The weights will change from their current values to the given endWeights, over startTime to endTime.
This is a permissioned function.
Since, unlike with swap fee updates, we generally do not want to allow instantaneous weight changes,
the weights always start from their current values. This also guarantees a smooth transition when
updateWeightsGradually is called during an ongoing weight change.*


```solidity
function updateWeightsGradually(uint256 startTime, uint256 endTime, IERC20[] memory tokens, uint256[] memory endWeights)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`startTime`|`uint256`|- The timestamp when the weight change will begin.|
|`endTime`|`uint256`|- The timestamp when the weight change will end (can be >= startTime).|
|`tokens`|`IERC20[]`|- The tokens associated with the target weights (must match the current pool tokens).|
|`endWeights`|`uint256[]`|- The target weights. If the current timestamp >= endTime, `getNormalizedWeights()` will return these values.|


### getNormalizedWeights

Returns all normalized weights, in the same order as the Pool's tokens.


```solidity
function getNormalizedWeights() external view returns (uint256[] memory);
```

### getGradualWeightUpdateParams

Returns the current gradual weight change update parameters.

*The current weights can be retrieved via `getNormalizedWeights()`.*


```solidity
function getGradualWeightUpdateParams()
    external
    view
    returns (uint256 startTime, uint256 endTime, uint256[] memory startWeights, uint256[] memory endWeights);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`startTime`|`uint256`|- The timestamp when the weight update will begin.|
|`endTime`|`uint256`|- The timestamp when the weight update will end.|
|`startWeights`|`uint256[]`|- The starting weights, when the weight change was initiated.|
|`endWeights`|`uint256[]`|- The final weights, when the current timestamp >= endTime.|


### setSwapEnabled

Enable or disable trading.

*Emits the SwapEnabledSet event. This is a permissioned function.*


```solidity
function setSwapEnabled(bool swapEnabled) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`swapEnabled`|`bool`|- The new value of the swap enabled flag.|


### getSwapEnabled

Returns whether swaps are enabled.


```solidity
function getSwapEnabled() external view returns (bool);
```

### setMustAllowlistLPs

Enable or disable the LP allowlist.

*Note that any addresses added to the allowlist will be retained if the allowlist is toggled off and
back on again, because this action does not affect the list of LP addresses.
Emits the MustAllowlistLPsSet event. This is a permissioned function.*


```solidity
function setMustAllowlistLPs(bool mustAllowlistLPs) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`mustAllowlistLPs`|`bool`|- The new value of the mustAllowlistLPs flag.|


### addAllowedAddress

Adds an address to the LP allowlist.

*Will fail if the address is already allowlisted.
Emits the AllowlistAddressAdded event. This is a permissioned function.*


```solidity
function addAllowedAddress(address member) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`member`|`address`|- The address to be added to the allowlist.|


### removeAllowedAddress

Removes an address from the LP allowlist.

*Will fail if the address was not previously allowlisted.
Emits the AllowlistAddressRemoved event. This is a permissioned function.*


```solidity
function removeAllowedAddress(address member) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`member`|`address`|- The address to be removed from the allowlist.|


### getMustAllowlistLPs

Returns whether the allowlist for LPs is enabled.


```solidity
function getMustAllowlistLPs() external view returns (bool);
```

### isAddressOnAllowlist

Check whether an LP address is on the allowlist.

*This simply checks the list, regardless of whether the allowlist feature is enabled.*


```solidity
function isAddressOnAllowlist(address member) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`member`|`address`|- The address to check against the allowlist.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if the given address is on the allowlist.|


### collectAumManagementFees

Collect any accrued AUM fees and send them to the pool manager.

*This can be called by anyone to collect accrued AUM fees - and will be called automatically
whenever the supply changes (e.g., joins and exits, add and remove token), and before the fee
percentage is changed by the manager, to prevent fees from being applied retroactively.*


```solidity
function collectAumManagementFees() external returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of BPT minted to the manager.|


### setManagementAumFeePercentage

Setter for the yearly percentage AUM management fee, which is payable to the pool manager.

*Attempting to collect AUM fees in excess of the maximum permitted percentage will revert.
To avoid retroactive fee increases, we force collection at the current fee percentage before processing
the update. Emits the ManagementAumFeePercentageChanged event. This is a permissioned function.*


```solidity
function setManagementAumFeePercentage(uint256 managementAumFeePercentage) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`managementAumFeePercentage`|`uint256`|- The new management AUM fee percentage.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|amount - The amount of BPT minted to the manager before the update, if any.|


### getManagementAumFeeParams

Returns the management AUM fee percentage as an 18-decimal fixed point number and the timestamp of the
last collection of AUM fees.


```solidity
function getManagementAumFeeParams()
    external
    view
    returns (uint256 aumFeePercentage, uint256 lastCollectionTimestamp);
```

### setCircuitBreakers

Set a circuit breaker for one or more tokens.

*This is a permissioned function. The lower and upper bounds are percentages, corresponding to a
relative change in the token's spot price: e.g., a lower bound of 0.8 means the breaker should prevent
trades that result in the value of the token dropping 20% or more relative to the rest of the pool.*


```solidity
function setCircuitBreakers(
    IERC20[] memory tokens,
    uint256[] memory bptPrices,
    uint256[] memory lowerBoundPercentages,
    uint256[] memory upperBoundPercentages
) external;
```

### getCircuitBreakerState

Return the full circuit breaker state for the given token.

*These are the reference values (BPT price and reference weight) passed in when the breaker was set,
along with the percentage bounds. It also returns the current BPT price bounds, needed to check whether
the circuit breaker should trip.*


```solidity
function getCircuitBreakerState(IERC20 token)
    external
    view
    returns (
        uint256 bptPrice,
        uint256 referenceWeight,
        uint256 lowerBound,
        uint256 upperBound,
        uint256 lowerBptPriceBound,
        uint256 upperBptPriceBound
    );
```

### addToken

Adds a token to the Pool's list of tradeable tokens. This is a permissioned function.

*By adding a token to the Pool's composition, the weights of all other tokens will be decreased. The new
token will have no balance - it is up to the owner to provide some immediately after calling this function.
Note however that regular join functions will not work while the new token has no balance: the only way to
deposit an initial amount is by using an Asset Manager.
Token addition is forbidden during a weight change, or if one is scheduled to happen in the future.
The caller may additionally pass a non-zero `mintAmount` to have some BPT be minted for them, which might be
useful in some scenarios to account for the fact that the Pool will have more tokens.
Emits the TokenAdded event.*


```solidity
function addToken(
    IERC20 tokenToAdd,
    address assetManager,
    uint256 tokenToAddNormalizedWeight,
    uint256 mintAmount,
    address recipient
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenToAdd`|`IERC20`|- The ERC20 token to be added to the Pool.|
|`assetManager`|`address`|- The Asset Manager for the token.|
|`tokenToAddNormalizedWeight`|`uint256`|- The normalized weight of `token` relative to the other tokens in the Pool.|
|`mintAmount`|`uint256`|- The amount of BPT to be minted as a result of adding `token` to the Pool.|
|`recipient`|`address`|- The address to receive the BPT minted by the Pool.|


### removeToken

Removes a token from the Pool's list of tradeable tokens.

*Tokens can only be removed if the Pool has more than 2 tokens, as it can never have fewer than 2 (not
including BPT). Token removal is also forbidden during a weight change, or if one is scheduled to happen in
the future.
Emits the TokenRemoved event. This is a permissioned function.
The caller may additionally pass a non-zero `burnAmount` to burn some of their BPT, which might be useful
in some scenarios to account for the fact that the Pool now has fewer tokens. This is a permissioned function.*


```solidity
function removeToken(IERC20 tokenToRemove, uint256 burnAmount, address sender) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenToRemove`|`IERC20`|- The ERC20 token to be removed from the Pool.|
|`burnAmount`|`uint256`|- The amount of BPT to be burned after removing `token` from the Pool.|
|`sender`|`address`|- The address to burn BPT from.|


## Events
### GradualSwapFeeUpdateScheduled

```solidity
event GradualSwapFeeUpdateScheduled(
    uint256 startTime, uint256 endTime, uint256 startSwapFeePercentage, uint256 endSwapFeePercentage
);
```

### GradualWeightUpdateScheduled

```solidity
event GradualWeightUpdateScheduled(uint256 startTime, uint256 endTime, uint256[] startWeights, uint256[] endWeights);
```

### SwapEnabledSet

```solidity
event SwapEnabledSet(bool swapEnabled);
```

### MustAllowlistLPsSet

```solidity
event MustAllowlistLPsSet(bool mustAllowlistLPs);
```

### AllowlistAddressAdded

```solidity
event AllowlistAddressAdded(address indexed member);
```

### AllowlistAddressRemoved

```solidity
event AllowlistAddressRemoved(address indexed member);
```

### ManagementAumFeePercentageChanged

```solidity
event ManagementAumFeePercentageChanged(uint256 managementAumFeePercentage);
```

### ManagementAumFeeCollected

```solidity
event ManagementAumFeeCollected(uint256 bptAmount);
```

### CircuitBreakerSet

```solidity
event CircuitBreakerSet(
    IERC20 indexed token, uint256 bptPrice, uint256 lowerBoundPercentage, uint256 upperBoundPercentage
);
```

### TokenAdded

```solidity
event TokenAdded(IERC20 indexed token, uint256 normalizedWeight);
```

### TokenRemoved

```solidity
event TokenRemoved(IERC20 indexed token);
```

