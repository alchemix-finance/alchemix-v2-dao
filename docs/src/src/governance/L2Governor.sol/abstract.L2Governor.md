# L2Governor
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/governance/L2Governor.sol)

**Inherits:**
Context, ERC165, EIP712, [IGovernor](/src/interfaces/IGovernor.sol/interface.IGovernor.md), IERC721Receiver, IERC1155Receiver

**Author:**
Modified from RollCall (https://github.com/withtally/rollcall/blob/main/src/standards/L2Governor.sol)

*Core of the governance system, designed to be extended though various modules.
This contract is abstract and requires several function to be implemented in various modules:
- A counting module must implement {quorum}, {_quorumReached}, {_voteSucceeded} and {_countVote}
- A voting module must implement {_getVotes}
- Additionanly, the {votingPeriod} must also be implemented
_Available since v4.3._*


## State Variables
### BALLOT_TYPEHASH

```solidity
bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");
```


### EXTENDED_BALLOT_TYPEHASH

```solidity
bytes32 public constant EXTENDED_BALLOT_TYPEHASH =
    keccak256("ExtendedBallot(uint256 proposalId,uint8 support,string reason,bytes params)");
```


### _timelock

```solidity
TimelockExecutor private _timelock;
```


### votingDelay

```solidity
uint256 public votingDelay = 2 days;
```


### votingPeriod

```solidity
uint256 public votingPeriod = 3 days;
```


### _name

```solidity
string private _name;
```


### _proposals

```solidity
mapping(uint256 => ProposalCore) private _proposals;
```


### _timelockIds

```solidity
mapping(uint256 => bytes32) private _timelockIds;
```


### _governanceCall

```solidity
DoubleEndedQueue.Bytes32Deque private _governanceCall;
```


## Functions
### onlyGovernance

*Restricts a function so it can only be executed through governance proposals. For example, governance
parameter setters in {GovernorSettings} are protected using this modifier.
The governance executing address may be different from the Governor's own address, for example it could be a
timelock. This can be customized by modules by overriding {_executor}. The executor is only able to invoke these
functions during the execution of the governor's {execute} function, and not under any other circumstances. Thus,
for example, additional timelock proposers are not able to change governance parameters without going through the
governance protocol (since v4.6).*


```solidity
modifier onlyGovernance();
```

### constructor

*Sets the value for {name}, {version}, and timelock address*


```solidity
constructor(string memory name_, TimelockExecutor timelockAddress) EIP712(name_, version());
```

### receive

*Function to receive ETH that will be handled by the governor (disabled if executor is a third party contract)*


```solidity
receive() external payable virtual;
```

### supportsInterface

*See {IERC165-supportsInterface}.*


```solidity
function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool);
```

### name

*See {IGovernor-name}.*


```solidity
function name() public view virtual override returns (string memory);
```

### version

*See {IGovernor-version}.*


```solidity
function version() public view virtual override returns (string memory);
```

### hashProposal

*See {IGovernor-hashProposal}.
The proposal id is produced by hashing the RLC encoded `targets` array, the `values` array, the `calldatas` array
and the descriptionHash (bytes32 which itself is the keccak256 hash of the description string). This proposal id
can be produced from the proposal data which is part of the {ProposalCreated} event. It can even be computed in
advance, before the proposal is submitted.
Note that the governor address is not part of the proposal id computation. Consequently, the
same proposal (with same operation and same description) will have the same id if submitted on multiple
governors in the same network. This also means that in order to execute the same operation twice (on the same
governor and network) the proposer will have to change the description in order to avoid proposal id conflicts.*


```solidity
function hashProposal(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash,
    uint256 chainId
) public pure virtual override returns (uint256);
```

### state

*See {IGovernor-state}.*


```solidity
function state(uint256 proposalId) public view virtual override returns (ProposalState);
```

### timelock

*Public accessor to check the address of the timelock*


```solidity
function timelock() public view virtual returns (address);
```

### proposalEta

*Public accessor to check the eta of a queued proposal*


```solidity
function proposalEta(uint256 proposalId) external view virtual returns (uint256);
```

### proposalSnapshot

*See {IGovernor-proposalSnapshot}.*


```solidity
function proposalSnapshot(uint256 proposalId) public view virtual override returns (uint256);
```

### proposalDeadline

*See {IGovernor-proposalDeadline}.*


```solidity
function proposalDeadline(uint256 proposalId) public view virtual override returns (uint256);
```

### proposalThreshold

*Part of the Governor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_.*

*This is overridden in AlchemixGovernor*


```solidity
function proposalThreshold() public view virtual returns (uint256);
```

### _quorumReached

*Amount of votes already cast passes the threshold limit.*


```solidity
function _quorumReached(uint256 proposalId) internal view virtual returns (bool);
```

### _voteSucceeded

*Is the proposal successful or not.*


```solidity
function _voteSucceeded(uint256 proposalId) internal view virtual returns (bool);
```

### _getVotes

*Get the voting weight of `tokenId` at a specific `blockTimestamp`, for a vote as described by `params`.*


```solidity
function _getVotes(address tokenId, uint256 blockTimestamp, bytes memory params)
    internal
    view
    virtual
    returns (uint256);
```

### _countVote

*Register a vote for `proposalId` by `account` with a given `support`, voting `weight` and voting `params`.
Note: Support is generic and can represent various things depending on the voting system used.*


```solidity
function _countVote(uint256 proposalId, address account, uint8 support, uint256 weight, bytes memory params)
    internal
    virtual;
```

### _defaultParams

*Default additional encoded parameters used by castVote methods that don't include them
Note: Should be overridden by specific implementations to use an appropriate value, the
meaning of the additional params, in the context of that implementation*


```solidity
function _defaultParams() internal view virtual returns (bytes memory);
```

### propose

*See {IGovernor-propose}.*


```solidity
function propose(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    string memory description,
    uint256 chainId
) public virtual override returns (uint256);
```

### execute

*See {IGovernor-execute}.*


```solidity
function execute(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash,
    uint256 chainId
) public payable virtual override returns (uint256);
```

### _execute

*Internal execution mechanism. Can be overridden to implement different execution mechanism*


```solidity
function _execute(
    uint256,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash,
    uint256 chainId
) internal virtual;
```

### _beforeExecute

*Hook before execution is triggered.*


```solidity
function _beforeExecute(uint256, address[] memory targets, uint256[] memory, bytes[] memory calldatas, bytes32, uint256)
    internal
    virtual;
```

### _afterExecute

*Hook after execution is triggered.*


```solidity
function _afterExecute(uint256, address[] memory, uint256[] memory, bytes[] memory, bytes32, uint256)
    internal
    virtual;
```

### cancel

*Governance cancel mechanism: locks up the proposal timer, preventing it from being re-submitted. Marks it as
canceled to allow distinguishing it from executed proposals.
Emits a {IGovernor-ProposalCanceled} event.*


```solidity
function cancel(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash,
    uint256 chainId
) internal virtual onlyGovernance returns (uint256);
```

### getVotes

*See {IGovernor-getVotes}.*


```solidity
function getVotes(address account, uint256 blockTimestamp) public view virtual override returns (uint256);
```

### getVotesWithParams

*See {IGovernor-getVotesWithParams}.*


```solidity
function getVotesWithParams(address account, uint256 blockTimestamp, bytes memory params)
    public
    view
    virtual
    override
    returns (uint256);
```

### castVote

*See {IGovernor-castVote}.*


```solidity
function castVote(uint256 proposalId, uint8 support) public virtual override returns (uint256);
```

### castVoteWithReason

*See {IGovernor-castVoteWithReason}.*


```solidity
function castVoteWithReason(uint256 proposalId, uint8 support, string calldata reason)
    public
    virtual
    override
    returns (uint256);
```

### castVoteWithReasonAndParams

*See {IGovernor-castVoteWithReasonAndParams}.*


```solidity
function castVoteWithReasonAndParams(uint256 proposalId, uint8 support, string calldata reason, bytes memory params)
    public
    virtual
    override
    returns (uint256);
```

### castVoteBySig

*See {IGovernor-castVoteBySig}.*


```solidity
function castVoteBySig(uint256 proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s)
    public
    virtual
    override
    returns (uint256);
```

### castVoteWithReasonAndParamsBySig

*See {IGovernor-castVoteWithReasonAndParamsBySig}.*


```solidity
function castVoteWithReasonAndParamsBySig(
    uint256 proposalId,
    uint8 support,
    string calldata reason,
    bytes memory params,
    uint8 v,
    bytes32 r,
    bytes32 s
) public virtual override returns (uint256);
```

### _castVote

*Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
voting weight using {IGovernor-getVotes} and call the {_countVote} internal function. Uses the _defaultParams().
Emits a {IGovernor-VoteCast} event.*


```solidity
function _castVote(uint256 proposalId, address account, uint8 support, string memory reason)
    internal
    virtual
    returns (uint256);
```

### _castVote

*Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
voting weight using {IGovernor-getVotes} and call the {_countVote} internal function.
Emits a {IGovernor-VoteCast} event.*


```solidity
function _castVote(uint256 proposalId, address account, uint8 support, string memory reason, bytes memory params)
    internal
    virtual
    returns (uint256);
```

### relay

*Relays a transaction or function call to an arbitrary target. In cases where the governance executor
is some contract other than the governor itself, like when using a timelock, this function can be invoked
in a governance proposal to recover tokens or Ether that was sent to the governor contract by mistake.
Note that if the executor is simply the governor itself, use of `relay` is redundant.*


```solidity
function relay(address target, uint256 value, bytes calldata data) external virtual onlyGovernance;
```

### _executor

*Address through which the governor executes action. In this case, the timelock.*


```solidity
function _executor() internal view virtual returns (address);
```

### updateTimelock

*Public endpoint to update the underlying timelock instance. Restricted to the timelock itself, so updates
must be proposed, scheduled, and executed through governance proposals.
CAUTION: It is not recommended to change the timelock while there are other queued governance proposals.*


```solidity
function updateTimelock(TimelockExecutor newTimelock) external virtual onlyGovernance;
```

### _updateTimelock


```solidity
function _updateTimelock(TimelockExecutor newTimelock) private;
```

### onERC721Received

*See {IERC721Receiver-onERC721Received}.*


```solidity
function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4);
```

### onERC1155Received

*See {IERC1155Receiver-onERC1155Received}.*


```solidity
function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4);
```

### onERC1155BatchReceived

*See {IERC1155Receiver-onERC1155BatchReceived}.*


```solidity
function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
    public
    virtual
    override
    returns (bytes4);
```

### removeAsset

*Callable by anyone to save assets that accidentally get sent to the governor*


```solidity
function removeAsset(address asset) external;
```

### removeNative

*Callable by anyone to save native tokens that accidentally get sent to the governor*


```solidity
function removeNative() external;
```

## Events
### AdminUpdated
*Emitted when a new admin is set.*


```solidity
event AdminUpdated(address admin);
```

### ProposalNumberSet
*Emitted when a new proposal number is set.*


```solidity
event ProposalNumberSet(uint256 numerator);
```

### TimelockChange
*Emitted when the timelock used for proposal execution is modified.*


```solidity
event TimelockChange(address oldTimelock, address newTimelock);
```

### VotingDelaySet
*Emitted when the voting delay is modified.*


```solidity
event VotingDelaySet(uint256 votingDelay);
```

### VotingPeriodSet
*Emitted when the voting period is modified.*


```solidity
event VotingPeriodSet(uint256 votingPeriod);
```

## Structs
### ProposalCore

```solidity
struct ProposalCore {
    Timers.Timestamp voteStart;
    Timers.Timestamp voteEnd;
    bool executed;
    bool canceled;
}
```

