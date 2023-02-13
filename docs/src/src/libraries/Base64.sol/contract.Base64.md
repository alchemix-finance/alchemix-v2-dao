# Base64
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/libraries/Base64.sol)

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

