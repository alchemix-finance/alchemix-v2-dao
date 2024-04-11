# ISignaturesValidator
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/helpers/ISignaturesValidator.sol)

*Interface for the SignatureValidator helper, used to support meta-transactions.*


## Functions
### getDomainSeparator

*Returns the EIP712 domain separator.*


```solidity
function getDomainSeparator() external view returns (bytes32);
```

### getNextNonce

*Returns the next nonce used by an address to sign messages.*


```solidity
function getNextNonce(address user) external view returns (uint256);
```

