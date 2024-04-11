# LogExpMath
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/balancer/LogExpMath.sol)

**Authors:**
Fernando Martinelli - @fernandomartinelli, Sergio Yuhjtman - @sergioyuhjtman, Daniel Fernandez - @dmf7z

*Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural
exponentiation and logarithm (where the base is Euler's number).*


## State Variables
### ONE_18

```solidity
int256 constant ONE_18 = 1e18;
```


### ONE_20

```solidity
int256 constant ONE_20 = 1e20;
```


### ONE_36

```solidity
int256 constant ONE_36 = 1e36;
```


### MAX_NATURAL_EXPONENT

```solidity
int256 constant MAX_NATURAL_EXPONENT = 130e18;
```


### MIN_NATURAL_EXPONENT

```solidity
int256 constant MIN_NATURAL_EXPONENT = -41e18;
```


### LN_36_LOWER_BOUND

```solidity
int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
```


### LN_36_UPPER_BOUND

```solidity
int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;
```


### MILD_EXPONENT_BOUND

```solidity
uint256 constant MILD_EXPONENT_BOUND = 2 ** 254 / uint256(ONE_20);
```


### x0

```solidity
int256 constant x0 = 128000000000000000000;
```


### a0

```solidity
int256 constant a0 = 38877084059945950922200000000000000000000000000000000000;
```


### x1

```solidity
int256 constant x1 = 64000000000000000000;
```


### a1

```solidity
int256 constant a1 = 6235149080811616882910000000;
```


### x2

```solidity
int256 constant x2 = 3200000000000000000000;
```


### a2

```solidity
int256 constant a2 = 7896296018268069516100000000000000;
```


### x3

```solidity
int256 constant x3 = 1600000000000000000000;
```


### a3

```solidity
int256 constant a3 = 888611052050787263676000000;
```


### x4

```solidity
int256 constant x4 = 800000000000000000000;
```


### a4

```solidity
int256 constant a4 = 298095798704172827474000;
```


### x5

```solidity
int256 constant x5 = 400000000000000000000;
```


### a5

```solidity
int256 constant a5 = 5459815003314423907810;
```


### x6

```solidity
int256 constant x6 = 200000000000000000000;
```


### a6

```solidity
int256 constant a6 = 738905609893065022723;
```


### x7

```solidity
int256 constant x7 = 100000000000000000000;
```


### a7

```solidity
int256 constant a7 = 271828182845904523536;
```


### x8

```solidity
int256 constant x8 = 50000000000000000000;
```


### a8

```solidity
int256 constant a8 = 164872127070012814685;
```


### x9

```solidity
int256 constant x9 = 25000000000000000000;
```


### a9

```solidity
int256 constant a9 = 128402541668774148407;
```


### x10

```solidity
int256 constant x10 = 12500000000000000000;
```


### a10

```solidity
int256 constant a10 = 113314845306682631683;
```


### x11

```solidity
int256 constant x11 = 6250000000000000000;
```


### a11

```solidity
int256 constant a11 = 106449445891785942956;
```


## Functions
### pow

*Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.*


```solidity
function pow(uint256 x, uint256 y) internal pure returns (uint256);
```

### exp

*Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.*


```solidity
function exp(int256 x) internal pure returns (int256);
```

### log

*Logarithm (log(arg, base), with signed 18 decimal fixed point base and argument.*


```solidity
function log(int256 arg, int256 base) internal pure returns (int256);
```

### ln

*Natural logarithm (ln(a)) with signed 18 decimal fixed point argument.*


```solidity
function ln(int256 a) internal pure returns (int256);
```

### _ln

*Internal natural logarithm (ln(a)) with signed 18 decimal fixed point argument.*


```solidity
function _ln(int256 a) private pure returns (int256);
```

### _ln_36

*Intrnal high precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point argument,
for x close to one.
Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.*


```solidity
function _ln_36(int256 x) private pure returns (int256);
```

