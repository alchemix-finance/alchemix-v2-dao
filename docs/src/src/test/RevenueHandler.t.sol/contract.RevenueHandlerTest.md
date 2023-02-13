# RevenueHandlerTest
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/test/RevenueHandler.t.sol)

**Inherits:**
[BaseTest](/src/test/BaseTest.sol/contract.BaseTest.md)


## State Variables
### ONE_EPOCH_TIME

```solidity
uint256 ONE_EPOCH_TIME = 1 weeks;
```


### ONE_EPOCH_BLOCKS

```solidity
uint256 ONE_EPOCH_BLOCKS = (1 weeks) / 12;
```


### alusdAlchemist

```solidity
IAlchemistV2 public alusdAlchemist = IAlchemistV2(0x5C6374a2ac4EBC38DeA0Fc1F8716e5Ea1AdD94dd);
```


### whitelist

```solidity
IWhitelist public whitelist = IWhitelist(0x78537a6CeBa16f412E123a90472C6E0e9A8F1132);
```


### cpa

```solidity
CurveMetaPoolAdapter cpa;
```


## Functions
### setUp

*Deploy the contract*


```solidity
function setUp() public;
```

### _accrueRevenue


```solidity
function _accrueRevenue(address token, uint256 amount) internal;
```

### _lockVeALCX


```solidity
function _lockVeALCX(uint256 amount) internal returns (uint256);
```

### _jumpOneEpoch


```solidity
function _jumpOneEpoch() internal;
```

### _initializeVeALCXPosition


```solidity
function _initializeVeALCXPosition(uint256 lockAmt) internal returns (uint256 tokenId);
```

### _accrueRevenueAndJumpOneEpoch


```solidity
function _accrueRevenueAndJumpOneEpoch(uint256 revAmt) internal;
```

### _setupClaimableRevenue


```solidity
function _setupClaimableRevenue(uint256 revAmt) internal returns (uint256 tokenId);
```

### _takeDebt


```solidity
function _takeDebt(uint256 amount) internal;
```

### testAddDebtToken


```solidity
function testAddDebtToken() external;
```

### testRemoveDebtToken


```solidity
function testRemoveDebtToken() external;
```

### testAddDebtTokenFail


```solidity
function testAddDebtTokenFail() external;
```

### testRemoveDebtTokenFail


```solidity
function testRemoveDebtTokenFail() external;
```

### testAddRevenueToken


```solidity
function testAddRevenueToken() external;
```

### testRemoveRevenueToken


```solidity
function testRemoveRevenueToken() external;
```

### testAddRevenueTokenFail


```solidity
function testAddRevenueTokenFail() external;
```

### testRemoveRevenueTokenFail


```solidity
function testRemoveRevenueTokenFail() external;
```

### testSetDebtToken


```solidity
function testSetDebtToken() external;
```

### testSetPoolAdapter


```solidity
function testSetPoolAdapter() external;
```

### testCheckpoint


```solidity
function testCheckpoint() external;
```

### testCheckpointRunsOncePerEpoch


```solidity
function testCheckpointRunsOncePerEpoch() external;
```

### testCheckpointMeltsAllRevenue


```solidity
function testCheckpointMeltsAllRevenue() external;
```

### testClaimOnlyApproved


```solidity
function testClaimOnlyApproved() external;
```

### testClaimRevenueOneEpoch


```solidity
function testClaimRevenueOneEpoch() external;
```

### testClaimRevenueMultipleEpochs


```solidity
function testClaimRevenueMultipleEpochs() external;
```

### testClaimPartialRevenue


```solidity
function testClaimPartialRevenue() external;
```

### testClaimTooMuch


```solidity
function testClaimTooMuch() external;
```

### testClaimMoreThanDebt


```solidity
function testClaimMoreThanDebt() external;
```

### testFirstClaimLate


```solidity
function testFirstClaimLate() external;
```

### testClaimBeforeAndAfterCheckpoint


```solidity
function testClaimBeforeAndAfterCheckpoint() external;
```

### testIncreaseVeALCXBeforeFirstClaim


```solidity
function testIncreaseVeALCXBeforeFirstClaim() external;
```

### testCheckpointETH


```solidity
function testCheckpointETH() external;
```

### testMultipleClaimers


```solidity
function testMultipleClaimers() external;
```

### testDisableRevenueToken


```solidity
function testDisableRevenueToken() external;
```

### testTreasuryRevenue


```solidity
function testTreasuryRevenue() external;
```

