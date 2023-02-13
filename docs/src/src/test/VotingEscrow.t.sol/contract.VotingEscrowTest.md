# VotingEscrowTest
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/test/VotingEscrow.t.sol)

**Inherits:**
[BaseTest](/src/test/BaseTest.sol/contract.BaseTest.md)


## State Variables
### ONE_WEEK

```solidity
uint256 internal constant ONE_WEEK = 1 weeks;
```


### maxDuration

```solidity
uint256 maxDuration = ((block.timestamp + MAXTIME) / ONE_WEEK) * ONE_WEEK;
```


## Functions
### setUp


```solidity
function setUp() public;
```

### testCreateLock


```solidity
function testCreateLock() public;
```

### testRewardPool


```solidity
function testRewardPool() public;
```

### testUpdateLockDuration


```solidity
function testUpdateLockDuration() public;
```

### testInvalidLock


```solidity
function testInvalidLock() public;
```

### testVotes


```solidity
function testVotes() public;
```

### testWithdraw


```solidity
function testWithdraw() public;
```

### testTokenURICalls


```solidity
function testTokenURICalls() public;
```

### testSupportedInterfaces


```solidity
function testSupportedInterfaces() public;
```

### testUnsupportedInterfaces


```solidity
function testUnsupportedInterfaces() public;
```

### testApprovedOrOwner


```solidity
function testApprovedOrOwner() public;
```

### testTransferToken


```solidity
function testTransferToken() public;
```

### testMergeTokens


```solidity
function testMergeTokens() public;
```

### testRagequit


```solidity
function testRagequit() public;
```

