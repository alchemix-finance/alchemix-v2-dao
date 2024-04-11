# Math
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/balancer/Math.sol)

*Wrappers over Solidity's arithmetic operations with added overflow checks.
Adapted from OpenZeppelin's SafeMath library.*


## Functions
### abs

*Returns the absolute value of a signed integer.*


```solidity
function abs(int256 a) internal pure returns (uint256 result);
```

### add

*Returns the addition of two unsigned integers of 256 bits, reverting on overflow.*


```solidity
function add(uint256 a, uint256 b) internal pure returns (uint256);
```

### add

*Returns the addition of two signed integers, reverting on overflow.*


```solidity
function add(int256 a, int256 b) internal pure returns (int256);
```

### sub

*Returns the subtraction of two unsigned integers of 256 bits, reverting on overflow.*


```solidity
function sub(uint256 a, uint256 b) internal pure returns (uint256);
```

### sub

*Returns the subtraction of two signed integers, reverting on overflow.*


```solidity
function sub(int256 a, int256 b) internal pure returns (int256);
```

### max

*Returns the largest of two numbers of 256 bits.*


```solidity
function max(uint256 a, uint256 b) internal pure returns (uint256 result);
```

### min

*Returns the smallest of two numbers of 256 bits.*


```solidity
function min(uint256 a, uint256 b) internal pure returns (uint256 result);
```

### mul


```solidity
function mul(uint256 a, uint256 b) internal pure returns (uint256);
```

### div


```solidity
function div(uint256 a, uint256 b, bool roundUp) internal pure returns (uint256);
```

### divDown


```solidity
function divDown(uint256 a, uint256 b) internal pure returns (uint256);
```

### divUp


```solidity
function divUp(uint256 a, uint256 b) internal pure returns (uint256 result);
```

