# StakingGaugeTest
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/test/StakingGauge.t.sol)

**Inherits:**
[BaseTest](/src/test/BaseTest.sol/contract.BaseTest.md)


## State Variables
### tokenId

```solidity
uint256 tokenId;
```


## Functions
### setUp


```solidity
function setUp() public;
```

### testEmergencyCouncilCanKillAndReviveGauges


```solidity
function testEmergencyCouncilCanKillAndReviveGauges() public;
```

### testFailCouncilCannotKillNonExistentGauge


```solidity
function testFailCouncilCannotKillNonExistentGauge() public;
```

### testFailNoOneElseCanKillGauges


```solidity
function testFailNoOneElseCanKillGauges() public;
```

### testKilledGaugeCannotDeposit


```solidity
function testKilledGaugeCannotDeposit() public;
```

### testKilledGaugeCanWithdraw


```solidity
function testKilledGaugeCanWithdraw() public;
```

### testKilledGaugeCanUpdateButGoesToZero


```solidity
function testKilledGaugeCanUpdateButGoesToZero() public;
```

### testKilledGaugeCanDistributeButGoesToZero


```solidity
function testKilledGaugeCanDistributeButGoesToZero() public;
```

### testCanStillDistroAllWithKilledGauge


```solidity
function testCanStillDistroAllWithKilledGauge() public;
```

