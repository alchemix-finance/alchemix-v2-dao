# function _revert
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/balancer/BalancerErrors.sol)

### _revert(uint256)
*Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
Uses the default 'BAL' prefix for the error code*


```solidity
function _revert(uint256 errorCode) pure;
```

### _revert(uint256, bytes3)
*Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.*


```solidity
function _revert(uint256 errorCode, bytes3 prefix) pure;
```

