# IFlashLoanRecipient
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/balancer/IFlashLoanRecipient.sol)


## Functions
### receiveFlashLoan

*When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
Vault, or else the entire flash loan will revert.
`userData` is the same value passed in the `IVault.flashLoan` call.*


```solidity
function receiveFlashLoan(
    IERC20[] memory tokens,
    uint256[] memory amounts,
    uint256[] memory feeAmounts,
    bytes memory userData
) external;
```

