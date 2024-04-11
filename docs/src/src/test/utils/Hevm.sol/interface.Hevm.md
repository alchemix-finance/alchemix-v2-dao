# Hevm
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/test/utils/Hevm.sol)


## Functions
### warp


```solidity
function warp(uint256) external;
```

### roll


```solidity
function roll(uint256) external;
```

### fee


```solidity
function fee(uint256) external;
```

### load


```solidity
function load(address account, bytes32 slot) external returns (bytes32);
```

### store


```solidity
function store(address account, bytes32 slot, bytes32 value) external;
```

### sign


```solidity
function sign(uint256 privateKey, bytes32 digest) external returns (uint8 v, bytes32 r, bytes32 s);
```

### addr


```solidity
function addr(uint256 privateKey) external returns (address);
```

### ffi


```solidity
function ffi(string[] calldata) external returns (bytes memory);
```

### prank


```solidity
function prank(address) external;
```

### startPrank


```solidity
function startPrank(address) external;
```

### prank


```solidity
function prank(address, address) external;
```

### startPrank


```solidity
function startPrank(address, address) external;
```

### stopPrank


```solidity
function stopPrank() external;
```

### deal


```solidity
function deal(address who, uint256 newBalance) external;
```

### etch


```solidity
function etch(address who, bytes calldata code) external;
```

### expectRevert


```solidity
function expectRevert(bytes calldata) external;
```

### expectRevert


```solidity
function expectRevert(bytes4) external;
```

### expectRevert


```solidity
function expectRevert() external;
```

### record


```solidity
function record() external;
```

### accesses


```solidity
function accesses(address) external returns (bytes32[] memory reads, bytes32[] memory writes);
```

### expectEmit


```solidity
function expectEmit(bool, bool, bool, bool) external;
```

### mockCall


```solidity
function mockCall(address, bytes calldata, bytes calldata) external;
```

### clearMockedCalls


```solidity
function clearMockedCalls() external;
```

### expectCall


```solidity
function expectCall(address, bytes calldata) external;
```

### getCode


```solidity
function getCode(string calldata) external returns (bytes memory);
```

### assume


```solidity
function assume(bool) external;
```

