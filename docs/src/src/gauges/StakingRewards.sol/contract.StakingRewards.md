# StakingRewards
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/gauges/StakingRewards.sol)

**Inherits:**
[IStakingRewards](/src/interfaces/synthetix/IStakingRewards.sol/contract.IStakingRewards.md), ReentrancyGuard, [Pausable](/src/external/Pausable.sol/contract.Pausable.md)


## State Variables
### rewardsDistribution

```solidity
address public rewardsDistribution;
```


### rewardsToken

```solidity
address public rewardsToken;
```


### stakingToken

```solidity
address public stakingToken;
```


### periodFinish

```solidity
uint256 public periodFinish = 0;
```


### rewardRate

```solidity
uint256 public rewardRate = 0;
```


### rewardsDuration

```solidity
uint256 public rewardsDuration = 7 days;
```


### lastUpdateTime

```solidity
uint256 public lastUpdateTime;
```


### rewardPerTokenStored

```solidity
uint256 public rewardPerTokenStored;
```


### userRewardPerTokenPaid

```solidity
mapping(address => uint256) public userRewardPerTokenPaid;
```


### rewards

```solidity
mapping(address => uint256) public rewards;
```


### _totalSupply

```solidity
uint256 private _totalSupply;
```


### _balances

```solidity
mapping(address => uint256) private _balances;
```


## Functions
### constructor


```solidity
constructor(address _owner, address _rewardsToken, address _stakingToken) public Owned(_owner);
```

### onlyRewardsDistribution


```solidity
modifier onlyRewardsDistribution();
```

### totalSupply


```solidity
function totalSupply() external view returns (uint256);
```

### balanceOf


```solidity
function balanceOf(address account) external view returns (uint256);
```

### lastTimeRewardApplicable


```solidity
function lastTimeRewardApplicable() public view returns (uint256);
```

### rewardPerToken


```solidity
function rewardPerToken() public view returns (uint256);
```

### earned


```solidity
function earned(address account) public view returns (uint256);
```

### getRewardForDuration


```solidity
function getRewardForDuration() external view returns (uint256);
```

### stake


```solidity
function stake(uint256 amount) external nonReentrant notPaused updateReward(msg.sender);
```

### withdraw


```solidity
function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender);
```

### getReward


```solidity
function getReward() public nonReentrant updateReward(msg.sender);
```

### exit


```solidity
function exit() external;
```

### setRewardsDistribution


```solidity
function setRewardsDistribution(address _rewardsDistribution) external onlyOwner;
```

### notifyRewardAmount


```solidity
function notifyRewardAmount(uint256 reward) external override onlyRewardsDistribution updateReward(address(0));
```

### recoverERC20


```solidity
function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner;
```

### setRewardsDuration


```solidity
function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner;
```

### updateReward


```solidity
modifier updateReward(address account);
```

## Events
### RewardAdded

```solidity
event RewardAdded(uint256 reward);
```

### Staked

```solidity
event Staked(address indexed user, uint256 amount);
```

### Withdrawn

```solidity
event Withdrawn(address indexed user, uint256 amount);
```

### RewardPaid

```solidity
event RewardPaid(address indexed user, uint256 reward);
```

### RewardsDurationUpdated

```solidity
event RewardsDurationUpdated(uint256 newDuration);
```

### Recovered

```solidity
event Recovered(address token, uint256 amount);
```

