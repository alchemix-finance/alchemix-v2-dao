# PassthroughGauge
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/gauges/PassthroughGauge.sol)

**Inherits:**
[BaseGauge](/src/BaseGauge.sol/contract.BaseGauge.md)

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


