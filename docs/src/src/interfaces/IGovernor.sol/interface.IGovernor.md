# IGovernor
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/IGovernor.sol)


## Functions
### name

module:core

*Name of the governor instance (used in building the ERC712 domain separator).*


```solidity
function name() external view returns (string memory);
```

### version

module:core

*Version of the governor instance (used in building the ERC712 domain separator). Default: "1"*


```solidity
function version() external view returns (string memory);
```

### COUNTING_MODE

module:voting

*A description of the possible `support` values for {castVote} and the way these votes are counted, meant to
be consumed by UIs to show correct vote options and interpret the results. The string is a URL-encoded sequence of
key-value pairs that each describe one aspect, for example `support=bravo&quorum=for,abstain`.
There are 2 standard keys: `support` and `quorum`.
- `support=bravo` refers to the vote options 0 = Against, 1 = For, 2 = Abstain, as in `GovernorBravo`.
- `quorum=bravo` means that only For votes are counted towards quorum.
- `quorum=for,abstain` means that both For and Abstain votes are counted towards quorum.
If a counting module makes use of encoded `params`, it should  include this under a `params` key with a unique
name that describes the behavior. For example:
- `params=fractional` might refer to a scheme where votes are divided fractionally between for/against/abstain.
- `params=erc721` might refer to a scheme where specific tokens are delegated to vote.
NOTE: The string can be decoded by the standard
https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams[`URLSearchParams`]
JavaScript class.*


```solidity
function COUNTING_MODE() external pure returns (string memory);
```

### hashProposal

module:core

*Hashing function used to (re)build the proposal id from the proposal details..*


```solidity
function hashProposal(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash,
    uint256 chainId
) external pure returns (uint256);
```

### state

module:core

*Current state of a proposal, following Compound's convention*


```solidity
function state(uint256 proposalId) external view returns (ProposalState);
```

### proposalSnapshot

module:core

*Block number used to retrieve user's votes and quorum. As per Compound's Comp and OpenZeppelin's
ERC20Votes, the snapshot is performed at the end of this block. Hence, voting for this proposal starts at the
beginning of the following block.*


```solidity
function proposalSnapshot(uint256 proposalId) external view returns (uint256);
```

### proposalDeadline

module:core

*Block number at which votes close. Votes close at the end of this block, so it is possible to cast a vote
during this block.*


```solidity
function proposalDeadline(uint256 proposalId) external view returns (uint256);
```

### votingDelay

module:user-config

*Delay, in number of block, between the proposal is created and the vote starts. This can be increassed to
leave time for users to buy voting power, of delegate it, before the voting of a proposal starts.*


```solidity
function votingDelay() external view returns (uint256);
```

### votingPeriod

module:user-config

*Delay, in number of blocks, between the vote start and vote ends.
NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
duration compared to the voting delay.*


```solidity
function votingPeriod() external view returns (uint256);
```

### quorum

module:user-config

*Minimum number of cast voted required for a proposal to be successful.
Note: The `blockNumber` parameter corresponds to the snapshot used for counting vote. This allows to scale the
quorum depending on values such as the totalSupply of a token at this block (see {ERC20Votes}).*


```solidity
function quorum(uint256 blockNumber) external view returns (uint256);
```

### getVotes

module:reputation

*Voting power of an `account` at a specific `blockNumber`.
Note: this can be implemented in a number of ways, for example by reading the delegated balance from one (or
multiple), {ERC20Votes} tokens.*


```solidity
function getVotes(address account, uint256 blockNumber) external view returns (uint256);
```

### getVotesWithParams

module:reputation

*Voting power of an `account` at a specific `blockNumber` given additional encoded parameters.*


```solidity
function getVotesWithParams(address account, uint256 blockNumber, bytes memory params)
    external
    view
    returns (uint256);
```

### hasVoted

module:voting

*Returns weither `account` has cast a vote on `proposalId`.*


```solidity
function hasVoted(uint256 proposalId, address account) external view returns (bool);
```

### propose

*Create a new proposal. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
{IGovernor-votingPeriod} blocks after the voting starts.
Emits a {ProposalCreated} event.*


```solidity
function propose(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    string memory description,
    uint256 chainId
) external returns (uint256 proposalId);
```

### execute

*Execute a successful proposal. This requires the quorum to be reached, the vote to be successful, and the
deadline to be reached.
Emits a {ProposalExecuted} event.
Note: some module can modify the requirements for execution, for example by adding an additional timelock.*


```solidity
function execute(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash,
    uint256 chainId
) external payable returns (uint256 proposalId);
```

### castVote

*Cast a vote
Emits a {VoteCast} event.*


```solidity
function castVote(uint256 proposalId, uint8 support) external returns (uint256 balance);
```

### castVoteWithReason

*Cast a vote with a reason
Emits a {VoteCast} event.*


```solidity
function castVoteWithReason(uint256 proposalId, uint8 support, string calldata reason)
    external
    returns (uint256 balance);
```

### castVoteWithReasonAndParams

*Cast a vote with a reason and additional encoded parameters
Emits a {VoteCast} or {VoteCastWithParams} event depending on the length of params.*


```solidity
function castVoteWithReasonAndParams(uint256 proposalId, uint8 support, string calldata reason, bytes memory params)
    external
    returns (uint256 balance);
```

### castVoteBySig

*Cast a vote using the user's cryptographic signature.
Emits a {VoteCast} event.*


```solidity
function castVoteBySig(uint256 proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s)
    external
    returns (uint256 balance);
```

### castVoteWithReasonAndParamsBySig

*Cast a vote with a reason and additional encoded parameters using the user's cryptographic signature.
Emits a {VoteCast} or {VoteCastWithParams} event depending on the length of params.*


```solidity
function castVoteWithReasonAndParamsBySig(
    uint256 proposalId,
    uint8 support,
    string calldata reason,
    bytes memory params,
    uint8 v,
    bytes32 r,
    bytes32 s
) external returns (uint256 balance);
```

## Events
### ProposalCreated
*Emitted when a proposal is created.*


```solidity
event ProposalCreated(
    uint256 proposalId,
    address proposer,
    address[] targets,
    uint256[] values,
    string[] signatures,
    bytes[] calldatas,
    uint256 startTime,
    uint256 endBlock,
    uint256 chainId
);
```

### ProposalCanceled
*Emitted when a proposal is canceled.*


```solidity
event ProposalCanceled(uint256 proposalId);
```

### ProposalExecuted
*Emitted when a proposal is executed.*


```solidity
event ProposalExecuted(uint256 proposalId);
```

### VoteCast
*Emitted when a vote is cast without params.
Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.*


```solidity
event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason);
```

### VoteCastWithParams
*Emitted when a vote is cast with params.
Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
`params` are additional encoded parameters. Their intepepretation also depends on the voting module used.*


```solidity
event VoteCastWithParams(
    address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason, bytes params
);
```

## Enums
### ProposalState

```solidity
enum ProposalState {
    Pending,
    Active,
    Canceled,
    Defeated,
    Succeeded,
    Queued,
    Expired,
    Executed
}
```

