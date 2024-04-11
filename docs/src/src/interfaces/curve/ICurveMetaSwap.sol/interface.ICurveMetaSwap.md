# ICurveMetaSwap
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/curve/ICurveMetaSwap.sol)


## Functions
### get_dy


```solidity
function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
```

### get_dy_underlying


```solidity
function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);
```

### exchange


```solidity
function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);
```

### exchange_underlying


```solidity
function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver)
    external
    returns (uint256);
```

