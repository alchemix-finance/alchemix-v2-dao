# MinterTest
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/test/Minter.t.sol)

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

### testCompoundRewards


```solidity
function testCompoundRewards() public;
```

### testCompoundRewardsFailure


```solidity
function testCompoundRewardsFailure() public;
```

### testAdminFunctions


```solidity
function testAdminFunctions() public;
```

