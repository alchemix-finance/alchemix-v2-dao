# Owned
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/external/Owned.sol)


## State Variables
### owner

```solidity
address public owner;
```


### nominatedOwner

```solidity
address public nominatedOwner;
```


## Functions
### constructor


```solidity
constructor(address _owner);
```

### nominateNewOwner


```solidity
function nominateNewOwner(address _owner) external onlyOwner;
```

### acceptOwnership


```solidity
function acceptOwnership() external;
```

### onlyOwner


```solidity
modifier onlyOwner();
```

### _onlyOwner


```solidity
function _onlyOwner() private view;
```

## Events
### OwnerNominated

```solidity
event OwnerNominated(address newOwner);
```

### OwnerChanged

```solidity
event OwnerChanged(address oldOwner, address newOwner);
```

