# Base64
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/libraries/Base64.sol)

**Author:**
Brecht Devos <brecht@loopring.org>

[MIT License]

Provides a function for encoding some bytes in base64


## State Variables
### TABLE

```solidity
bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
```


## Functions
### encode

Encodes some bytes to the base64 representation


```solidity
function encode(bytes memory data) internal pure returns (string memory);
```

