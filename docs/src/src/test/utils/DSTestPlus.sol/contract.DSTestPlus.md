# DSTestPlus
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/test/utils/DSTestPlus.sol)

**Inherits:**
Test

**Author:**
Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/test/utils/DSTestPlus.sol)

Extended testing framework for DappTools projects.


## State Variables
### hevm

```solidity
Hevm internal constant hevm = Hevm(HEVM_ADDRESS);
```


### DEAD_ADDRESS

```solidity
address internal constant DEAD_ADDRESS = 0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF;
```


### checkpointLabel

```solidity
string private checkpointLabel;
```


### checkpointGasLeft

```solidity
uint256 private checkpointGasLeft;
```


## Functions
### startMeasuringGas


```solidity
function startMeasuringGas(string memory label) internal virtual;
```

### stopMeasuringGas


```solidity
function stopMeasuringGas() internal virtual;
```

### assertUint128Eq


```solidity
function assertUint128Eq(uint128 a, uint128 b) internal virtual;
```

### assertUint64Eq


```solidity
function assertUint64Eq(uint64 a, uint64 b) internal virtual;
```

### assertUint96Eq


```solidity
function assertUint96Eq(uint96 a, uint96 b) internal virtual;
```

### assertUint32Eq


```solidity
function assertUint32Eq(uint32 a, uint32 b) internal virtual;
```

### assertBoolEq


```solidity
function assertBoolEq(bool a, bool b) internal virtual;
```

### assertApproxEq


```solidity
function assertApproxEq(uint256 a, uint256 b, uint256 maxDelta) internal virtual;
```

### assertRelApproxEq


```solidity
function assertRelApproxEq(uint256 a, uint256 b, uint256 maxPercentDelta) internal virtual;
```

### assertBytesEq


```solidity
function assertBytesEq(bytes memory a, bytes memory b) internal virtual;
```

### assertUintArrayEq


```solidity
function assertUintArrayEq(uint256[] memory a, uint256[] memory b) internal virtual;
```

### expectError


```solidity
function expectError(string memory message) internal;
```

### min3


```solidity
function min3(uint256 a, uint256 b, uint256 c) internal pure returns (uint256);
```

### min2


```solidity
function min2(uint256 a, uint256 b) internal pure returns (uint256);
```

