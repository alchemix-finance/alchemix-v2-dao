# L2GovernorCountingSimple
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/governance/L2GovernorCountingSimple.sol)

**Inherits:**
[L2Governor](/src/governance/L2Governor.sol/contract.L2Governor.md), [L2GovernorVotesQuorumFraction](/src/governance/L2GovernorVotesQuorumFraction.sol/contract.L2GovernorVotesQuorumFraction.md)

**Author:**
Modified from RollCall (https://github.com/withtally/rollcall/blob/main/src/standards/L2GovernorCountingSimple.sol)

*Extension of {Governor} for simple, 3 options, vote counting.
_Available since v4.3._*


## State Variables
### _proposalVotes

```solidity
mapping(uint256 => ProposalVote) private _proposalVotes;
```


## Functions
### COUNTING_MODE

*See {IGovernor-COUNTING_MODE}.*


```solidity
function COUNTING_MODE() public pure virtual override returns (string memory);
```

### hasVoted

*See {IGovernor-hasVoted}.*


```solidity
function hasVoted(uint256 proposalId, address account) public view virtual override returns (bool);
```

### proposalVotes

*Accessor to the internal vote counts.*


```solidity
function proposalVotes(uint256 proposalId)
    public
    view
    virtual
    returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes);
```

### _quorumReached

*See {Governor-_quorumReached}.*


```solidity
function _quorumReached(uint256 proposalId) internal view virtual override returns (bool);
```

### _voteSucceeded

*See {Governor-_voteSucceeded}. In this module, the forVotes must be strictly over the againstVotes.*


```solidity
function _voteSucceeded(uint256 proposalId) internal view virtual override returns (bool);
```

### _countVote

*See {Governor-_countVote}. In this module, the support follows the `VoteType` enum (from Governor Bravo).*


```solidity
function _countVote(uint256 proposalId, address account, uint8 support, uint256 weight, bytes memory)
    internal
    virtual
    override;
```

## Structs
### ProposalVote

```solidity
struct ProposalVote {
    uint256 againstVotes;
    uint256 forVotes;
    uint256 abstainVotes;
    mapping(address => bool) hasVoted;
}
```

## Enums
### VoteType
*Supported vote types. Matches Governor Bravo ordering.*


```solidity
enum VoteType {
    Against,
    For,
    Abstain
}
```

