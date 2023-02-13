# IAuthorizer
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/balancer/IAuthorizer.sol)


## Functions
### canPerform

*Returns true if `account` can perform the action described by `actionId` in the contract `where`.*


```solidity
function canPerform(bytes32 actionId, address account, address where) external view returns (bool);
```

