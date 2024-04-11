# function _revert
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/balancer/BalancerErrors.sol)

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

