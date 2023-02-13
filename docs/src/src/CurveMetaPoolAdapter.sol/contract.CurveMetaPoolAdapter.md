# CurveMetaPoolAdapter
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/CurveMetaPoolAdapter.sol)

**Inherits:**
[IPoolAdapter](/src/interfaces/IPoolAdapter.sol/contract.IPoolAdapter.md)


## State Variables
### pool

```solidity
address public override pool;
```


### tokenIds

```solidity
mapping(address => int128) public tokenIds;
```


## Functions
### constructor


```solidity
constructor(address _pool, address[] memory _tokens);
```

### getDy


```solidity
function getDy(address inputToken, address outputToken, uint256 inputAmount) external view override returns (uint256);
```

### melt


```solidity
function melt(address inputToken, address outputToken, uint256 inputAmount, uint256 minimumAmountOut)
    external
    override
    returns (uint256);
```

