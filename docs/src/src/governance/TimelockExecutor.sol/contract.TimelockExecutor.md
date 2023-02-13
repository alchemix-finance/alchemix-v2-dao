# TimelockExecutor
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/governance/TimelockExecutor.sol)

**Inherits:**
IERC721Receiver, IERC1155Receiver

*Contract module which acts as a timelocked controller. When set as the
owner of an `Ownable` smart contract, it enforces a timelock on all
`onlyOwner` maintenance operations. This gives time for users of the
controlled contract to exit before a potentially dangerous maintenance
operation is applied.
By default, this contract is self administered, meaning administration tasks
have to go through the timelock process. The admin
is in charge of operations. A common use case is
to position this {TimelockExecutor} as the owner of a smart contract, with
a multisig or a DAO as the admin.
_Available since v3.3._*


## State Variables
### admin

```solidity
address public admin;
```


### pendingAdmin

```solidity
address public pendingAdmin;
```


### _DONE_TIMESTAMP

```solidity
uint256 internal constant _DONE_TIMESTAMP = uint256(1);
```


### _timestamps

```solidity
mapping(bytes32 => uint256) private _timestamps;
```


### _delay

```solidity
uint256 private _delay;
```


## Functions
### constructor

*Initializes the contract with a given `delay`, and an admin.*


```solidity
constructor(uint256 delay);
```

### receive

*Contract might receive/hold ETH as part of the maintenance process.*


```solidity
receive() external payable;
```

### setAdmin


```solidity
function setAdmin(address _admin) external;
```

### acceptAdmin


```solidity
function acceptAdmin() external;
```

### supportsInterface

*See {IERC165-supportsInterface}.*


```solidity
function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool);
```

### isOperation

*Returns whether an id correspond to a registered operation. This
includes both Pending, Ready and Done operations.*


```solidity
function isOperation(bytes32 id) public view virtual returns (bool pending);
```

### isOperationPending

*Returns whether an operation is pending or not.*


```solidity
function isOperationPending(bytes32 id) public view virtual returns (bool pending);
```

### isOperationReady

*Returns whether an operation is ready or not.*


```solidity
function isOperationReady(bytes32 id) public view virtual returns (bool ready);
```

### isOperationDone

*Returns whether an operation is done or not.*


```solidity
function isOperationDone(bytes32 id) public view virtual returns (bool done);
```

### getTimestamp

*Returns the timestamp at with an operation becomes ready (0 for
unset operations, 1 for done operations).*


```solidity
function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp);
```

### getDelay

*Returns the delay for an operation to become valid.
This value can be changed by executing an operation that calls `updateDelay`.*


```solidity
function getDelay() public view virtual returns (uint256 duration);
```

### hashOperation

*Returns the identifier of an operation containing a single
transaction.*


```solidity
function hashOperation(
    address target,
    uint256 value,
    bytes calldata callData,
    bytes32 predecessor,
    bytes32 descriptionHash,
    uint256 chainId
) public pure virtual returns (bytes32 hash);
```

### hashOperationBatch

*Returns the identifier of an operation containing a batch of
transactions.*


```solidity
function hashOperationBatch(
    address[] calldata targets,
    uint256[] calldata values,
    bytes[] calldata calldatas,
    bytes32 predecessor,
    bytes32 descriptionHash,
    uint256 chainId
) public pure virtual returns (bytes32 hash);
```

### schedule

*Schedule an operation containing a single transaction.
Emits a {CallScheduled} event.
Requirements:
- the caller must be the 'admin'.*


```solidity
function schedule(
    address target,
    uint256 value,
    bytes calldata data,
    bytes32 predecessor,
    bytes32 descriptionHash,
    uint256 chainId,
    uint256 delay
) public virtual;
```

### scheduleBatch

*Schedule an operation containing a batch of transactions.
Emits one {CallScheduled} event per transaction in the batch.
Requirements:
- the caller must be the 'admin'.*


```solidity
function scheduleBatch(
    address[] calldata targets,
    uint256[] calldata values,
    bytes[] calldata payloads,
    bytes32 predecessor,
    bytes32 descriptionHash,
    uint256 chainId,
    uint256 delay
) public virtual;
```

### _schedule

*Schedule an operation that is to becomes valid after a given delay.*


```solidity
function _schedule(bytes32 id, uint256 delay) private;
```

### execute

*Execute an (ready) operation containing a single transaction.
Emits a {CallExecuted} event.*


```solidity
function execute(
    address target,
    uint256 value,
    bytes calldata data,
    bytes32 predecessor,
    bytes32 descriptionHash,
    uint256 chainId
) public payable virtual;
```

### executeBatch

*Execute an (ready) operation containing a batch of transactions.
Emits one {CallExecuted} event per transaction in the batch.*


```solidity
function executeBatch(
    address[] calldata targets,
    uint256[] calldata values,
    bytes[] calldata payloads,
    bytes32 predecessor,
    bytes32 descriptionHash,
    uint256 chainId
) public payable virtual;
```

### _beforeCall

*Checks before execution of an operation's calls.*


```solidity
function _beforeCall(bytes32 id, bytes32 predecessor) private view;
```

### _afterCall

*Checks after execution of an operation's calls.*


```solidity
function _afterCall(bytes32 id) private;
```

### _execute

*Execute an operation's call.*


```solidity
function _execute(bytes32 id, uint256 index, address target, uint256 value, bytes calldata data) private;
```

### updateDelay

*Changes the minimum timelock duration for future operations.
Emits a {DelayChange} event.
Requirements:
- the caller must be the timelock itself. This can only be achieved by scheduling and later executing
an operation where the timelock is the target and the data is the ABI-encoded call to this function.*


```solidity
function updateDelay(uint256 newDelay) external virtual;
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

## Events
### CallScheduled
*Emitted when a call is scheduled as part of operation `id`.*


```solidity
event CallScheduled(
    bytes32 indexed id,
    uint256 indexed index,
    address target,
    uint256 value,
    bytes data,
    bytes32 predecessor,
    uint256 delay
);
```

### CallExecuted
*Emitted when a call is performed as part of operation `id`.*


```solidity
event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);
```

### Cancelled
*Emitted when operation `id` is cancelled.*


```solidity
event Cancelled(bytes32 indexed id);
```

### DelayChange
*Emitted when the delay for future operations is modified.*


```solidity
event DelayChange(uint256 oldDuration, uint256 newDuration);
```

