# IProtocolFeesCollector
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/balancer/IProtocolFeesCollector.sol)


## Functions
### withdrawCollectedFees


```solidity
function withdrawCollectedFees(IERC20[] calldata tokens, uint256[] calldata amounts, address recipient) external;
```

### setSwapFeePercentage


```solidity
function setSwapFeePercentage(uint256 newSwapFeePercentage) external;
```

### setFlashLoanFeePercentage


```solidity
function setFlashLoanFeePercentage(uint256 newFlashLoanFeePercentage) external;
```

### getSwapFeePercentage


```solidity
function getSwapFeePercentage() external view returns (uint256);
```

### getFlashLoanFeePercentage


```solidity
function getFlashLoanFeePercentage() external view returns (uint256);
```

### getCollectedFeeAmounts


```solidity
function getCollectedFeeAmounts(IERC20[] memory tokens) external view returns (uint256[] memory feeAmounts);
```

### getAuthorizer


```solidity
function getAuthorizer() external view returns (IAuthorizer);
```

### vault


```solidity
function vault() external view returns (IVault);
```

## Events
### SwapFeePercentageChanged

```solidity
event SwapFeePercentageChanged(uint256 newSwapFeePercentage);
```

### FlashLoanFeePercentageChanged

```solidity
event FlashLoanFeePercentageChanged(uint256 newFlashLoanFeePercentage);
```

