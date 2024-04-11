# IRewardPool4626
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/aura/IRewardPool4626.sol)


## Functions
### withdraw


```solidity
function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
```

### deposit


```solidity
function deposit(uint256 assets, address receiver) external returns (uint256 shares);
```

### asset


```solidity
function asset() external view returns (address);
```

### balanceOf


```solidity
function balanceOf(address account) external view returns (uint256);
```

### processIdleRewards


```solidity
function processIdleRewards() external;
```

