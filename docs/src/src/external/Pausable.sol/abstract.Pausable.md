# Pausable
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/external/Pausable.sol)

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

