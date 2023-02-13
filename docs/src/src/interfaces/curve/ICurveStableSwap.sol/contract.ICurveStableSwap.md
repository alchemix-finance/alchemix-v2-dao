# ICurveStableSwap
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/curve/ICurveStableSwap.sol)


## Functions
### get_dy


```solidity
function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
```

### exchange


```solidity
function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver)
    external
    payable
    returns (uint256);
```

