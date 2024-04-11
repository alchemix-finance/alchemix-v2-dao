# MockCurveGauge
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/aura/MockCurveGauge.sol)

**Inherits:**
ERC20


## State Variables
### lp_token

```solidity
address public lp_token;
```


### reward_tokens

```solidity
address[] public reward_tokens;
```


### rewards_receiver

```solidity
mapping(address => address) public rewards_receiver;
```


## Functions
### constructor


```solidity
constructor(string memory _name, string memory _symbol, address _lptoken, address[] memory _rewardTokens)
    ERC20(_name, _symbol);
```

### deposit


```solidity
function deposit(uint256 amount) external;
```

### withdraw


```solidity
function withdraw(uint256 amount) external;
```

### claim_rewards


```solidity
function claim_rewards() external;
```

### claimable_reward


```solidity
function claimable_reward(address, address) external pure returns (uint256);
```

### deposit_reward_token


```solidity
function deposit_reward_token(address, uint256) external;
```

### add_reward


```solidity
function add_reward(address, address) external;
```

### is_killed


```solidity
function is_killed() external pure returns (bool);
```

### set_rewards_receiver


```solidity
function set_rewards_receiver(address receiver) external;
```

