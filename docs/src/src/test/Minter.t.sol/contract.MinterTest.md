# MinterTest
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/test/Minter.t.sol)

**Inherits:**
[BaseTest](/src/test/BaseTest.sol/contract.BaseTest.md)


## State Variables
### epochsUntilTail

```solidity
uint256 epochsUntilTail = 80;
```


### tokenId

```solidity
uint256 tokenId;
```


## Functions
### setUp


```solidity
function setUp() public;
```

### testEpochEmissions


```solidity
function testEpochEmissions() external;
```

### testTailEmissions


```solidity
function testTailEmissions() external;
```

### initializeVotingEscrow


```solidity
function initializeVotingEscrow() public;
```

### testWeeklyEmissionsSchedule


```solidity
function testWeeklyEmissionsSchedule() public;
```

### testClaimRewardsEarly


```solidity
function testClaimRewardsEarly() public;
```

### testRewardsWithinEpoch


```solidity
function testRewardsWithinEpoch() public;
```

### testCompoundRewards


```solidity
function testCompoundRewards() public;
```

### testCompoundRewardsFailure


```solidity
function testCompoundRewardsFailure() public;
```

### testCompoundRewardsFailureETH


```solidity
function testCompoundRewardsFailureETH() public;
```

### testAdminFunctions


```solidity
function testAdminFunctions() public;
```

### testSetTreasury


```solidity
function testSetTreasury() public;
```

