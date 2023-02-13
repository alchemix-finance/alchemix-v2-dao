# StakingPools
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/StakingPools.sol)


## Functions
### acceptGovernance


```solidity
function acceptGovernance() external;
```

### claim


```solidity
function claim(uint256 _poolId) external;
```

### createPool


```solidity
function createPool(address _token) external returns (uint256);
```

### deposit


```solidity
function deposit(uint256 _poolId, uint256 _depositAmount) external;
```

### exit


```solidity
function exit(uint256 _poolId) external;
```

### getPoolRewardRate


```solidity
function getPoolRewardRate(uint256 _poolId) external view returns (uint256);
```

### getPoolRewardWeight


```solidity
function getPoolRewardWeight(uint256 _poolId) external view returns (uint256);
```

### getPoolToken


```solidity
function getPoolToken(uint256 _poolId) external view returns (address);
```

### getPoolTotalDeposited


```solidity
function getPoolTotalDeposited(uint256 _poolId) external view returns (uint256);
```

### getStakeTotalDeposited


```solidity
function getStakeTotalDeposited(address _account, uint256 _poolId) external view returns (uint256);
```

### getStakeTotalUnclaimed


```solidity
function getStakeTotalUnclaimed(address _account, uint256 _poolId) external view returns (uint256);
```

### governance


```solidity
function governance() external view returns (address);
```

### pendingGovernance


```solidity
function pendingGovernance() external view returns (address);
```

### poolCount


```solidity
function poolCount() external view returns (uint256);
```

### reward


```solidity
function reward() external view returns (address);
```

### rewardRate


```solidity
function rewardRate() external view returns (uint256);
```

### setPendingGovernance


```solidity
function setPendingGovernance(address _pendingGovernance) external;
```

### setRewardRate


```solidity
function setRewardRate(uint256 _rewardRate) external;
```

### setRewardWeights


```solidity
function setRewardWeights(uint256[] memory _rewardWeights) external;
```

### tokenPoolIds


```solidity
function tokenPoolIds(address) external view returns (uint256);
```

### totalRewardWeight


```solidity
function totalRewardWeight() external view returns (uint256);
```

### withdraw


```solidity
function withdraw(uint256 _poolId, uint256 _withdrawAmount) external;
```

