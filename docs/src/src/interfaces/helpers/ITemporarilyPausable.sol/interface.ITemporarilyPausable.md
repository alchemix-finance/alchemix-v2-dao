# ITemporarilyPausable
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/helpers/ITemporarilyPausable.sol)

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

