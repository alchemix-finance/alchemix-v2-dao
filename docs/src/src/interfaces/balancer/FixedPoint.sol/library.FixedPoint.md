# FixedPoint
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/balancer/FixedPoint.sol)


## State Variables
### ONE

```solidity
uint256 internal constant ONE = 1e18;
```


### TWO

```solidity
uint256 internal constant TWO = 2 * ONE;
```


### FOUR

```solidity
uint256 internal constant FOUR = 4 * ONE;
```


### MAX_POW_RELATIVE_ERROR

```solidity
uint256 internal constant MAX_POW_RELATIVE_ERROR = 10_000;
```


### MIN_POW_BASE_FREE_EXPONENT

```solidity
uint256 internal constant MIN_POW_BASE_FREE_EXPONENT = 0.7e18;
```


## Functions
### add


```solidity
function add(uint256 a, uint256 b) internal pure returns (uint256);
```

### sub


```solidity
function sub(uint256 a, uint256 b) internal pure returns (uint256);
```

### mulDown


```solidity
function mulDown(uint256 a, uint256 b) internal pure returns (uint256);
```

### mulUp


```solidity
function mulUp(uint256 a, uint256 b) internal pure returns (uint256 result);
```

### divDown


```solidity
function divDown(uint256 a, uint256 b) internal pure returns (uint256);
```

### divUp


```solidity
function divUp(uint256 a, uint256 b) internal pure returns (uint256 result);
```

### powDown

*Returns x^y, assuming both are fixed point numbers, rounding down. The result is guaranteed to not be above
the true value (that is, the error function expected - actual is always positive).*


```solidity
function powDown(uint256 x, uint256 y) internal pure returns (uint256);
```

### powUp

*Returns x^y, assuming both are fixed point numbers, rounding up. The result is guaranteed to not be below
the true value (that is, the error function expected - actual is always negative).*


```solidity
function powUp(uint256 x, uint256 y) internal pure returns (uint256);
```

### complement

*Returns the complement of a value (1 - x), capped to 0 if x is larger than 1.
Useful when computing the complement for values with some level of relative error, as it strips this error and
prevents intermediate negative values.*


```solidity
function complement(uint256 x) internal pure returns (uint256 result);
```

