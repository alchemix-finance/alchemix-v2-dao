# L2GovernorVotesQuorumFraction
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/governance/L2GovernorVotesQuorumFraction.sol)

**Inherits:**
[L2GovernorVotes](/src/governance/L2GovernorVotes.sol/contract.L2GovernorVotes.md)

**Author:**
Modified from RollCall (https://github.com/withtally/rollcall/blob/main/src/standards/L2GovernorVotesQuorumFraction.sol)

*Extension of {Governor} for voting weight extraction from an {ERC20Votes} token and a quorum expressed as a
fraction of the total supply.
_Available since v4.3._*


## State Variables
### _quorumNumerator

```solidity
uint256 private _quorumNumerator;
```


## Functions
### constructor

*Initialize quorum as a fraction of the token's total supply.
The fraction is specified as `numerator / denominator`. By default the denominator is 100, so quorum is
specified as a percent: a numerator of 10 corresponds to quorum being 10% of total supply. The denominator can be
customized by overriding {quorumDenominator}.*


```solidity
constructor(uint256 quorumNumeratorValue);
```

### quorumNumerator

*Returns the current quorum numerator. See {quorumDenominator}.*


```solidity
function quorumNumerator() public view virtual returns (uint256);
```

### quorumDenominator

*Returns the quorum denominator. Defaults to 100, but may be overridden.*


```solidity
function quorumDenominator() public view virtual returns (uint256);
```

### quorum

*Returns the quorum for a block timestamp, in terms of number of votes: `supply * numerator / denominator`.*


```solidity
function quorum(uint256 blockTimestamp) public view virtual override returns (uint256);
```

### updateQuorumNumerator

*Changes the quorum numerator.
Emits a {QuorumNumeratorUpdated} event.
Requirements:
- Must be called through a governance proposal.
- New numerator must be smaller or equal to the denominator.*


```solidity
function updateQuorumNumerator(uint256 newQuorumNumerator) external virtual onlyGovernance;
```

### _updateQuorumNumerator

*Changes the quorum numerator.
Emits a {QuorumNumeratorUpdated} event.
Requirements:
- New numerator must be smaller or equal to the denominator.*


```solidity
function _updateQuorumNumerator(uint256 newQuorumNumerator) internal virtual;
```

## Events
### QuorumNumeratorUpdated

```solidity
event QuorumNumeratorUpdated(uint256 oldQuorumNumerator, uint256 newQuorumNumerator);
```

