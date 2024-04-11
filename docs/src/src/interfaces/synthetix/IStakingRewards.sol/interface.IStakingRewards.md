# IStakingRewards
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/synthetix/IStakingRewards.sol)


## Functions
### balanceOf


```solidity
function balanceOf(address account) external view returns (uint256);
```

### earned


```solidity
function earned(address account) external view returns (uint256);
```

### getRewardForDuration


```solidity
function getRewardForDuration() external view returns (uint256);
```

### lastTimeRewardApplicable


```solidity
function lastTimeRewardApplicable() external view returns (uint256);
```

### rewardPerToken


```solidity
function rewardPerToken() external view returns (uint256);
```

### rewardsDistribution


```solidity
function rewardsDistribution() external view returns (address);
```

### rewardsToken


```solidity
function rewardsToken() external view returns (address);
```

### totalSupply


```solidity
function totalSupply() external view returns (uint256);
```

### exit


```solidity
function exit() external;
```

### getReward


```solidity
function getReward() external;
```

### stake


```solidity
function stake(uint256 amount) external;
```

### withdraw


```solidity
function withdraw(uint256 amount) external;
```

### notifyRewardAmount


```solidity
function notifyRewardAmount(uint256 reward) external;
```

