# ITemporarilyPausable
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/helpers/ITemporarilyPausable.sol)

*Interface for the TemporarilyPausable helper.*


## Functions
### getPausedState

*Returns the current paused state.*


```solidity
function getPausedState()
    external
    view
    returns (bool paused, uint256 pauseWindowEndTime, uint256 bufferPeriodEndTime);
```

## Events
### PausedStateChanged
*Emitted every time the pause state changes by `_setPaused`.*


```solidity
event PausedStateChanged(bool paused);
```

