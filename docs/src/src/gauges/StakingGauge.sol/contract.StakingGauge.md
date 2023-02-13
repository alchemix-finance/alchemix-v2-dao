# StakingGauge
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/gauges/StakingGauge.sol)

**Inherits:**
[BaseGauge](/src/BaseGauge.sol/contract.BaseGauge.md)

Gauge to handle ALCX staking


## Functions
### constructor


```solidity
constructor(address _stake, address _bribe, address _ve, address _voter);
```

### depositAll


```solidity
function depositAll(uint256 tokenId) external;
```

### deposit


```solidity
function deposit(uint256 amount, uint256 tokenId) public lock;
```

### withdrawAll


```solidity
function withdrawAll() external;
```

### withdraw


```solidity
function withdraw(uint256 amount) public;
```

### withdrawToken


```solidity
function withdrawToken(uint256 amount, uint256 tokenId) public lock;
```

## Events
### Deposit

```solidity
event Deposit(address indexed from, uint256 tokenId, uint256 amount);
```

### Withdraw

```solidity
event Withdraw(address indexed from, uint256 tokenId, uint256 amount);
```

