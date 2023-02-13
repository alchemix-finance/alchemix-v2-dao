# Pausable
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/external/Pausable.sol)

**Inherits:**
[Owned](/src/external/Owned.sol/contract.Owned.md)


## State Variables
### lastPauseTime

```solidity
uint256 public lastPauseTime;
```


### paused

```solidity
bool public paused;
```


## Functions
### constructor


```solidity
constructor();
```

### setPaused

Change the paused state of the contract

*Only the contract owner may call this.*


```solidity
function setPaused(bool _paused) external onlyOwner;
```

### notPaused


```solidity
modifier notPaused();
```

## Events
### PauseChanged

```solidity
event PauseChanged(bool isPaused);
```

