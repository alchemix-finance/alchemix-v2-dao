# AlchemixGovernor
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/AlchemixGovernor.sol)

**Inherits:**
[L2Governor](/src/governance/L2Governor.sol/contract.L2Governor.md), [L2GovernorVotes](/src/governance/L2GovernorVotes.sol/contract.L2GovernorVotes.md), [L2GovernorVotesQuorumFraction](/src/governance/L2GovernorVotesQuorumFraction.sol/contract.L2GovernorVotesQuorumFraction.md), [L2GovernorCountingSimple](/src/governance/L2GovernorCountingSimple.sol/contract.L2GovernorCountingSimple.md)

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
uint256 public constant MAX_PROPOSAL_NUMERATOR = 50;
```


### PROPOSAL_DENOMINATOR

```solidity
uint256 public constant PROPOSAL_DENOMINATOR = 1000;
```


### proposalNumerator

```solidity
uint256 public proposalNumerator = 2;
```


## Functions
### constructor


```solidity
constructor(IVotes _ve, TimelockExecutor timelockAddress)
    L2Governor("Alchemix Governor", timelockAddress)
    L2GovernorVotes(_ve)
    L2GovernorVotesQuorumFraction(4);
```

### proposalThreshold


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

