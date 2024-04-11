# CurveEthPoolAdapter
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/CurveEthPoolAdapter.sol)

**Inherits:**
[IPoolAdapter](/src/interfaces/IPoolAdapter.sol/interface.IPoolAdapter.md)


## State Variables
### pool

```solidity
address public immutable override pool;
```


### tokenIds

```solidity
mapping(address => int128) public tokenIds;
```


### isMetapool

```solidity
bool public isMetapool;
```


### weth

```solidity
address public immutable weth;
```


## Functions
### constructor


```solidity
constructor(address _pool, address[] memory _tokens, address _weth);
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

### receive


```solidity
receive() external payable;
```

