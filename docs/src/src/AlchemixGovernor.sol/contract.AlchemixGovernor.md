# AlchemixGovernor
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/AlchemixGovernor.sol)

**Inherits:**
[L2Governor](/src/governance/L2Governor.sol/abstract.L2Governor.md), [L2GovernorVotes](/src/governance/L2GovernorVotes.sol/abstract.L2GovernorVotes.md), [L2GovernorVotesQuorumFraction](/src/governance/L2GovernorVotesQuorumFraction.sol/abstract.L2GovernorVotesQuorumFraction.md), [L2GovernorCountingSimple](/src/governance/L2GovernorCountingSimple.sol/abstract.L2GovernorCountingSimple.md)

Alchemix specific governance parameters

*Extends the Open Zeppelin governance system*


## State Variables
### admin

```solidity
address public admin;
```


### pendingAdmin

```solidity
address public pendingAdmin;
```


### MAX_PROPOSAL_NUMERATOR

```solidity
uint256 public constant MAX_PROPOSAL_NUMERATOR = 5000;
```


### PROPOSAL_DENOMINATOR

```solidity
uint256 public constant PROPOSAL_DENOMINATOR = 10_000;
```


### proposalNumerator

```solidity
uint256 public proposalNumerator = 400;
```


### quorumNumeratorValue

```solidity
uint256 public quorumNumeratorValue = 2000;
```


## Functions
### constructor


```solidity
constructor(IVotes _ve, TimelockExecutor timelockAddress)
    L2Governor("Alchemix Governor", timelockAddress)
    L2GovernorVotes(_ve)
    L2GovernorVotesQuorumFraction(quorumNumeratorValue);
```

### proposalThreshold

*Part of the Governor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_.*


```solidity
function proposalThreshold() public view override(L2Governor) returns (uint256);
```

### setAdmin


```solidity
function setAdmin(address _admin) external;
```

### acceptAdmin


```solidity
function acceptAdmin() external;
```

### setProposalNumerator


```solidity
function setProposalNumerator(uint256 numerator) external;
```

### setVotingDelay


```solidity
function setVotingDelay(uint256 newDelay) external;
```

### setVotingPeriod


```solidity
function setVotingPeriod(uint256 newPeriod) external;
```

