# VotingEscrowTest
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/test/VotingEscrow.t.sol)

**Inherits:**
[BaseTest](/src/test/BaseTest.sol/contract.BaseTest.md)


## State Variables
### ONE_WEEK

```solidity
uint256 internal constant ONE_WEEK = 1 weeks;
```


### THREE_WEEKS

```solidity
uint256 internal constant THREE_WEEKS = 3 weeks;
```


### FIVE_WEEKS

```solidity
uint256 internal constant FIVE_WEEKS = 5 weeks;
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

### testCreateLockFailed


```solidity
function testCreateLockFailed() public;
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

### testPastVotesIndex


```solidity
function testPastVotesIndex() public;
```

### testBalanceOfTokenCalcs


```solidity
function testBalanceOfTokenCalcs() public;
```

### testDisableMaxLock


```solidity
function testDisableMaxLock() public;
```

### testWithdraw


```solidity
function testWithdraw() public;
```

### testFluxAccrual


```solidity
function testFluxAccrual() public;
```

### testRewardsClaiming


```solidity
function testRewardsClaiming() public;
```

### testTokenURICalls


```solidity
function testTokenURICalls() public;
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

### testMergeSupplyImpact


```solidity
function testMergeSupplyImpact() public;
```

### testManipulateEarlyUnlock


```solidity
function testManipulateEarlyUnlock() public;
```

### testRagequit


```solidity
function testRagequit() public;
```

### testCircumventLockingPeriod


```solidity
function testCircumventLockingPeriod() public;
```

### testRagequitSupplyImpact


```solidity
function testRagequitSupplyImpact() public;
```

### testFluxAccrualOverTime


```solidity
function testFluxAccrualOverTime() public;
```

### testGetPastTotalSupply


```solidity
function testGetPastTotalSupply() public;
```

### testTotalSupplyAtT


```solidity
function testTotalSupplyAtT() public;
```

### testBalanceOfTokenAt


```solidity
function testBalanceOfTokenAt() public;
```

### testManipulatePastBalanceWithDeposit


```solidity
function testManipulatePastBalanceWithDeposit(uint256 time) public;
```

### testManipulatePastSupplyWithDeposit


```solidity
function testManipulatePastSupplyWithDeposit() public;
```

### testTotalSupplyWithMaxlock


```solidity
function testTotalSupplyWithMaxlock() public;
```

### testMovingDelegates


```solidity
function testMovingDelegates() public;
```

