# PassthroughGauge
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/gauges/PassthroughGauge.sol)

**Inherits:**
[BaseGauge](/src/BaseGauge.sol/abstract.BaseGauge.md)

Generic gauge to handle distribution of rewards without pool specific passthrough logic

*If custom distribution logic is necessary create additional contract*


## Functions
### constructor


```solidity
constructor(address _receiver, address _bribe, address _ve, address _voter);
```

### _passthroughRewards

Pass rewards to pool


```solidity
function _passthroughRewards(uint256 _amount) internal override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Amount of rewards|


