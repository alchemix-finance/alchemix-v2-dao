# IAuthorizer
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/balancer/IAuthorizer.sol)


## Functions
### canPerform

*Returns true if `account` can perform the action described by `actionId` in the contract `where`.*


```solidity
function canPerform(bytes32 actionId, address account, address where) external view returns (bool);
```

