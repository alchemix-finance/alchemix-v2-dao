# VotingEscrow
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/VotingEscrow.sol)

**Inherits:**
IERC721, IERC721Metadata, IVotes, [IVotingEscrow](/src/interfaces/IVotingEscrow.sol/interface.IVotingEscrow.md)

veALCX implementation that escrows ERC-20 tokens in the form of an ERC-721 token

Votes have a weight depending on time, so that users are committed to the future of (whatever they are voting for)

*Vote weight decays linearly over time. Lock time cannot be more than `MAXTIME` (1 year).*


## State Variables
### name

```solidity
string public constant name = "veALCX";
```


### symbol

```solidity
string public constant symbol = "veALCX";
```


### version

```solidity
string public constant version = "1.0.0";
```


### decimals

```solidity
uint8 public immutable decimals = 18;
```


### EPOCH

```solidity
uint256 public constant EPOCH = 2 weeks;
```


### MAX_DELEGATES

```solidity
uint256 public constant MAX_DELEGATES = 1024;
```


### MAXTIME

```solidity
uint256 public constant MAXTIME = 365 days;
```


### MULTIPLIER

```solidity
uint256 public constant MULTIPLIER = 2;
```


### WEEK

```solidity
uint256 internal immutable WEEK = 1 weeks;
```


### BPS

```solidity
uint256 internal immutable BPS = 10_000;
```


### iMAXTIME

```solidity
int256 internal constant iMAXTIME = 365 days;
```


### iMULTIPLIER

```solidity
int256 internal constant iMULTIPLIER = 2;
```


### tokenId
*Current count of token*


```solidity
uint256 internal tokenId;
```


### ALCX

```solidity
address public immutable ALCX;
```


### FLUX

```solidity
address public immutable FLUX;
```


### BPT

```solidity
address public immutable BPT;
```


### rewardPoolManager

```solidity
address public rewardPoolManager;
```


### admin

```solidity
address public admin;
```


### pendingAdmin

```solidity
address public pendingAdmin;
```


### voter

```solidity
address public voter;
```


### distributor

```solidity
address public distributor;
```


### treasury

```solidity
address public treasury;
```


### supply

```solidity
uint256 public supply;
```


### claimFeeBps

```solidity
uint256 public claimFeeBps = 5000;
```


### fluxMultiplier

```solidity
uint256 public fluxMultiplier;
```


### fluxPerVeALCX

```solidity
uint256 public fluxPerVeALCX;
```


### epoch

```solidity
uint256 public epoch;
```


### locked

```solidity
mapping(uint256 => LockedBalance) public locked;
```


### ownershipChange

```solidity
mapping(uint256 => uint256) public ownershipChange;
```


### pointHistory

```solidity
mapping(uint256 => Point) public pointHistory;
```


### userPointHistory

```solidity
mapping(uint256 => Point[1000000000]) public userPointHistory;
```


### userFirstEpoch

```solidity
mapping(uint256 => uint256) public userFirstEpoch;
```


### userPointEpoch

```solidity
mapping(uint256 => uint256) public userPointEpoch;
```


### slopeChanges

```solidity
mapping(uint256 => int256) public slopeChanges;
```


### attachments

```solidity
mapping(uint256 => uint256) public attachments;
```


### voted

```solidity
mapping(uint256 => bool) public voted;
```


### isRewardPoolToken

```solidity
mapping(address => bool) public isRewardPoolToken;
```


### idToOwner
*Mapping from token ID to the address that owns it.*


```solidity
mapping(uint256 => address) internal idToOwner;
```


### idToApprovals
*Mapping from token ID to approved address.*


```solidity
mapping(uint256 => address) internal idToApprovals;
```


### ownerToTokenCount
*Mapping from owner address to count of his tokens.*


```solidity
mapping(address => uint256) internal ownerToTokenCount;
```


### ownerToTokenIdList
*Mapping from owner address to mapping of index to tokenIds*


```solidity
mapping(address => mapping(uint256 => uint256)) internal ownerToTokenIdList;
```


### tokenToOwnerIndex
*Mapping from token ID to index of owner*


```solidity
mapping(uint256 => uint256) internal tokenToOwnerIndex;
```


### ownerToOperators
*Mapping from owner address to mapping of operator addresses.*


```solidity
mapping(address => mapping(address => bool)) internal ownerToOperators;
```


### _delegates
A record of each accounts delegate


```solidity
mapping(address => address) private _delegates;
```


### checkpoints
A record of delegated token checkpoints for each account, by index


```solidity
mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;
```


### numCheckpoints
The number of checkpoints for each account


```solidity
mapping(address => uint32) public numCheckpoints;
```


### nonces
A record of states for signing / validating signatures


```solidity
mapping(address => uint256) public nonces;
```


### NOT_ENTERED
*reentrancy guard*


```solidity
uint8 internal constant NOT_ENTERED = 1;
```


### ENTERED

```solidity
uint8 internal constant ENTERED = 2;
```


### ENTERED_STATE

```solidity
uint8 internal ENTERED_STATE = 1;
```


## Functions
### nonreentrant


```solidity
modifier nonreentrant();
```

### constructor

Contract constructor


```solidity
constructor(address _bpt, address _alcx, address _flux, address _treasury);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_bpt`|`address`|`BPT` token address|
|`_alcx`|`address`|`ALCX` token address|
|`_flux`|`address`|`FLUX` token address|
|`_treasury`|`address`||


### getTokenIds

Get the tokenIds for a given address from the last checkpoint


```solidity
function getTokenIds(address _address) external view returns (uint256[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_address`|`address`|Address of the user|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256[]`|Array of tokenIds|


### supportsInterface


```solidity
function supportsInterface(bytes4 _interfaceID) external pure returns (bool);
```

### getLastUserSlope

Get the most recently recorded rate of voting power decrease for `_tokenId`


```solidity
function getLastUserSlope(uint256 _tokenId) external view returns (int256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|int256 Value of the slope|


### userPointHistoryTimestamp

Get the timestamp for checkpoint `_idx` for `_tokenId`


```solidity
function userPointHistoryTimestamp(uint256 _tokenId, uint256 _idx) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token|
|`_idx`|`uint256`|Epoch number|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Epoch time of the checkpoint|


### pointHistoryTimestamp

Get the timestamp for checkpoint `_idx`


```solidity
function pointHistoryTimestamp(uint256 _idx) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_idx`|`uint256`|Epoch number|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Epoch time of the checkpoint|


### lockEnd

Get timestamp when `_tokenId`'s lock finishes


```solidity
function lockEnd(uint256 _tokenId) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Epoch time of the lock end|


### isMaxLocked


```solidity
function isMaxLocked(uint256 _tokenId) public view returns (bool);
```

### lockedAmount

Get amount locked for `_tokenId`


```solidity
function lockedAmount(uint256 _tokenId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Amount locked|


### cooldownEnd

Get timestamp when `_tokenId`'s cooldown finishes


```solidity
function cooldownEnd(uint256 _tokenId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Epoch time of the cooldown end|


### getPointHistory


```solidity
function getPointHistory(uint256 _loc) external view returns (Point memory);
```

### getUserPointHistory


```solidity
function getUserPointHistory(uint256 _tokenId, uint256 _loc) external view returns (Point memory);
```

### balanceOf

Returns the number of tokens owned by `_owner`.

*Throws if `_owner` is the zero address. tokens assigned to the zero address are considered invalid.*


```solidity
function balanceOf(address _owner) external view override(IERC721, IVotingEscrow) returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_owner`|`address`|Address for whom to query the balance.|


### ownerOf

Returns the address of the owner of the token.


```solidity
function ownerOf(uint256 _tokenId) public view override(IERC721, IVotingEscrow) returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`||


### getApproved

Get the approved address for a single token.


```solidity
function getApproved(uint256 _tokenId) external view override(IERC721, IVotingEscrow) returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token to query the approval of.|


### isApprovedForAll

Checks if `_operator` is an approved operator for `_owner`.


```solidity
function isApprovedForAll(address _owner, address _operator)
    external
    view
    override(IERC721, IVotingEscrow)
    returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_owner`|`address`|The address that owns the tokens.|
|`_operator`|`address`|The address that acts on behalf of the owner.|


### tokenOfOwnerByIndex

Get token by index


```solidity
function tokenOfOwnerByIndex(address _owner, uint256 _tokenIndex) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_owner`|`address`|Address of the user|
|`_tokenIndex`|`uint256`|Index of the token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Token ID|


### isApprovedOrOwner


```solidity
function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool);
```

### delegates

Overrides the standard `Comp.sol` delegates mapping to return
the delegator's own address if they haven't delegated.
This avoids having to delegate to oneself.


```solidity
function delegates(address delegator) public view returns (address);
```

### getVotes

Gets the current votes balance for `account`


```solidity
function getVotes(address account) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address to get votes balance|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The number of current votes for `account`|


### getPastVotesIndex


```solidity
function getPastVotesIndex(address account, uint256 timestamp) public view returns (uint32);
```

### getPastVotes

*Returns the amount of votes that `account` had at the end of a past `timestamp`.*


```solidity
function getPastVotes(address account, uint256 timestamp) public view returns (uint256);
```

### getPastTotalSupply


```solidity
function getPastTotalSupply(uint256 timestamp) external view returns (uint256);
```

### amountToRagequit

Amount of FLUX required to ragequit for a given token

*Amount to ragequit should be a function of the voting power*


```solidity
function amountToRagequit(uint256 _tokenId) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Amount of FLUX required to ragequit|


### tokenURI

Returns current token URI metadata


```solidity
function tokenURI(uint256 _tokenId) external view returns (string memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token to fetch URI for.|


### balanceOfToken


```solidity
function balanceOfToken(uint256 _tokenId) external view returns (uint256);
```

### balanceOfTokenAt


```solidity
function balanceOfTokenAt(uint256 _tokenId, uint256 _time) external view returns (uint256);
```

### claimableFlux

Amount of flux claimable at current epoch

*flux should accrue at the ragequit amount divided by the fluxMultiplier per epoch*


```solidity
function claimableFlux(uint256 _tokenId) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Amount of claimable flux for the current epoch|


### totalSupplyAtT

Calculate total voting power

*Adheres to the ERC20 `totalSupply` interface for Aragon compatibility*


```solidity
function totalSupplyAtT(uint256 t) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`t`|`uint256`|Timestamp provided|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Total voting power|


### totalSupply

Calculate total voting power

*Adheres to the ERC20 `totalSupply` interface for Aragon compatibility*


```solidity
function totalSupply() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Total voting power|


### setTreasury

Set the treasury address


```solidity
function setTreasury(address _treasury) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_treasury`|`address`|Address of the new treasury|


### transferFrom

*Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this token.
Throws if `_from` is not the current owner.
Throws if `_to` is the zero address.
Throws if `_tokenId` is not a valid token.*


```solidity
function transferFrom(address _from, address _to, uint256 _tokenId) external override(IERC721, IVotingEscrow);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_from`|`address`|The current owner of the token.|
|`_to`|`address`|The new owner.|
|`_tokenId`|`uint256`|ID of the token to transfer.|


### safeTransferFrom

Transfers the ownership of an token from one address to another address.

*Throws unless `msg.sender` is the current owner, an authorized operator, or the
approved address for this token.
Throws if `_from` is not the current owner.
Throws if `_to` is the zero address.
Throws if `_tokenId` is not a valid token.
If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
the return value is not `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.*


```solidity
function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_from`|`address`|The current owner of the token.|
|`_to`|`address`|The new owner.|
|`_tokenId`|`uint256`|ID of the token to transfer.|
|`_data`|`bytes`|Additional data with no specified format, sent in call to `_to`.|


### safeTransferFrom

Transfers the ownership of an token from one address to another address.

*Throws unless `msg.sender` is the current owner, an authorized operator, or the
approved address for this token.
Throws if `_from` is not the current owner.
Throws if `_to` is the zero address.
Throws if `_tokenId` is not a valid token.
If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
the return value is not `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.*


```solidity
function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_from`|`address`|The current owner of the token.|
|`_to`|`address`|The new owner.|
|`_tokenId`|`uint256`|ID of the token to transfer.|


### approve

Set or reaffirm the approved address for an token. The zero address indicates there is no approved address.

*Throws unless `msg.sender` is the current token owner, or an authorized operator of the current owner.
Throws if `_tokenId` is not a valid token. (NOTE: This is not written the EIP)
Throws if `_approved` is the current owner. (NOTE: This is not written the EIP)*


```solidity
function approve(address _approved, uint256 _tokenId) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_approved`|`address`|Address to be approved for the given token ID.|
|`_tokenId`|`uint256`|ID of the token to be approved.|


### setApprovalForAll

Enables or disables approval for a third party ("operator") to manage all of `msg.sender`'s assets.

This works even if sender doesn't own any tokens at the time.

*Throws if `_operator` is the `msg.sender`. (This is not written the EIP)*

*emits the ApprovalForAll event.*


```solidity
function setApprovalForAll(address _operator, bool _approved) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_operator`|`address`|Address to add to the set of authorized operators.|
|`_approved`|`bool`|True if the operators is approved, false to revoke approval.|


### delegate

Delegate votes from `msg.sender` to `delegatee`


```solidity
function delegate(address delegatee) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`delegatee`|`address`|The address to delegate votes to|


### delegateBySig


```solidity
function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s)
    public
    override;
```

### setVoter


```solidity
function setVoter(address _voter) external;
```

### setRewardsDistributor


```solidity
function setRewardsDistributor(address _distributor) external;
```

### setRewardPoolManager


```solidity
function setRewardPoolManager(address _rewardPoolManager) external;
```

### voting


```solidity
function voting(uint256 _tokenId) external;
```

### abstain


```solidity
function abstain(uint256 _tokenId) external;
```

### attach


```solidity
function attach(uint256 _tokenId) external;
```

### detach


```solidity
function detach(uint256 _tokenId) external;
```

### setfluxMultiplier


```solidity
function setfluxMultiplier(uint256 _fluxMultiplier) external;
```

### setAdmin


```solidity
function setAdmin(address _admin) external;
```

### acceptAdmin


```solidity
function acceptAdmin() external;
```

### setfluxPerVeALCX


```solidity
function setfluxPerVeALCX(uint256 _fluxPerVeALCX) external;
```

### setClaimFee


```solidity
function setClaimFee(uint256 _claimFeeBps) external;
```

### merge


```solidity
function merge(uint256 _from, uint256 _to) external;
```

### checkpoint

Record global data to checkpoint


```solidity
function checkpoint() external;
```

### updateLock

Update lock end for max locked tokens

*This ensures token will continue to accrue flux*


```solidity
function updateLock(uint256 _tokenId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`||


### depositFor

Deposit `_value` tokens for `_tokenId` and add to the lock

*Anyone (even a smart contract) can deposit for someone else, but
cannot extend their locktime and deposit for a brand new user*


```solidity
function depositFor(uint256 _tokenId, uint256 _value) external nonreentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`||
|`_value`|`uint256`||


### createLockFor

Deposit `_value` tokens for `_to` and lock for `_lockDuration`


```solidity
function createLockFor(uint256 _value, uint256 _lockDuration, bool _maxLockEnabled, address _to)
    external
    nonreentrant
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_value`|`uint256`|Amount to deposit|
|`_lockDuration`|`uint256`|Number of seconds to lock tokens for (rounded down to nearest week)|
|`_maxLockEnabled`|`bool`|Is max lock enabled|
|`_to`|`address`|Address to deposit|


### createLock

Deposit `_value` tokens for `msg.sender` and lock for `_lockDuration`


```solidity
function createLock(uint256 _value, uint256 _lockDuration, bool _maxLockEnabled)
    external
    nonreentrant
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_value`|`uint256`|Amount to deposit|
|`_lockDuration`|`uint256`|Number of seconds to lock tokens for (rounded down to nearest week)|
|`_maxLockEnabled`|`bool`|Is max lock enabled|


### updateUnlockTime

Extend the unlock time for `_tokenId`


```solidity
function updateUnlockTime(uint256 _tokenId, uint256 _lockDuration, bool _maxLockEnabled) external nonreentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`||
|`_lockDuration`|`uint256`|New number of seconds until tokens unlock|
|`_maxLockEnabled`|`bool`|Is max lock being enabled|


### withdraw

Withdraw all tokens for `_tokenId`

*Only possible if the lock has expired*


```solidity
function withdraw(uint256 _tokenId) public nonreentrant;
```

### startCooldown

Starts the cooldown for `_tokenId`

*If lock is not expired cooldown can only be started by burning FLUX*


```solidity
function startCooldown(uint256 _tokenId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`||


### _balance

Returns the number of tokens owned by `_owner`.

*Throws if `_owner` is the zero address. tokens assigned to the zero address are considered invalid.*


```solidity
function _balance(address _owner) internal view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_owner`|`address`|Address for whom to query the balance.|


### _isApprovedOrOwner

Returns whether the given spender can transfer a given token ID


```solidity
function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_spender`|`address`|address of the spender to query|
|`_tokenId`|`uint256`|ID of the token to be transferred|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool whether the msg.sender is approved for the given token ID, is an operator of the owner, or is the owner of the token|


### _addTokenToOwnerList

Add a token to an index mapping to a given address


```solidity
function _addTokenToOwnerList(address _to, uint256 _tokenId) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_to`|`address`|address of the receiver|
|`_tokenId`|`uint256`|ID of the token to be added|


### _removeTokenFromOwnerList

Remove a token from an index mapping to a given address


```solidity
function _removeTokenFromOwnerList(address _from, uint256 _tokenId) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_from`|`address`|address of the sender|
|`_tokenId`|`uint256`|ID of the token to be removed|


### _addTokenTo

Add a token to a given address

*Throws if `_tokenId` is owned by someone.*


```solidity
function _addTokenTo(address _to, uint256 _tokenId) internal;
```

### _removeTokenFrom

Remove a token from a given address

*Throws if `_from` is not the current owner.*


```solidity
function _removeTokenFrom(address _from, uint256 _tokenId) internal;
```

### _clearApproval

Clear an approval of a given address

*Throws if `_owner` is not the current owner.*


```solidity
function _clearApproval(address _owner, uint256 _tokenId) internal;
```

### _transferFrom

Execute transfer of a token.

*Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
address for this token. (NOTE: `msg.sender` not allowed in internal function so pass `_sender`.)
Throws if `_to` is the zero address.
Throws if `_from` is not the current owner.*


```solidity
function _transferFrom(address _from, address _to, uint256 _tokenId, address _sender) internal;
```

### _isContract


```solidity
function _isContract(address account) internal view returns (bool);
```

### _mint

Function to mint tokens

*Throws if `_to` is zero address.
Throws if `_tokenId` is owned by someone.*


```solidity
function _mint(address _to, uint256 _tokenId) internal returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_to`|`address`|The address that will receive the minted tokens.|
|`_tokenId`|`uint256`|ID of the token to mint.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool indication if the operation was successful.|


### _findWhatCheckpointToWrite


```solidity
function _findWhatCheckpointToWrite(address account) internal view returns (uint32);
```

### _moveTokenDelegates


```solidity
function _moveTokenDelegates(address src, address dst, uint256 _tokenId) internal;
```

### _moveAllDelegates


```solidity
function _moveAllDelegates(address owner, address src, address dst) internal;
```

### _delegate


```solidity
function _delegate(address delegator, address delegatee) internal;
```

### _calculatePoint

differs from `_delegate()` in `Comp.sol` to use `delegates` override method to simulate auto-delegation

Calculate slope and bias taking into account if max lock is enabled


```solidity
function _calculatePoint(LockedBalance memory _locked, uint256 _time) internal pure returns (Point memory point);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_locked`|`LockedBalance`|LockedBalance struct|
|`_time`|`uint256`|time to calculate point at|


### _checkpoint

Record global and per-user data to checkpoint


```solidity
function _checkpoint(uint256 _tokenId, LockedBalance memory oldLocked, LockedBalance memory newLocked) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token. No user checkpoint if 0|
|`oldLocked`|`LockedBalance`|Pevious locked amount / end lock time for the user|
|`newLocked`|`LockedBalance`|New locked amount / end lock time for the user|


### _depositFor

Deposit and lock tokens for a user


```solidity
function _depositFor(
    uint256 _tokenId,
    uint256 _value,
    uint256 unlockTime,
    bool _maxLockEnabled,
    LockedBalance memory lockedBalance,
    DepositType depositType
) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token that holds lock|
|`_value`|`uint256`|Amount to deposit|
|`unlockTime`|`uint256`|New time when to unlock the tokens, or 0 if unchanged|
|`_maxLockEnabled`|`bool`||
|`lockedBalance`|`LockedBalance`|Previous locked amount / timestamp|
|`depositType`|`DepositType`|The type of deposit|


### _createLock

Deposit `_value` tokens for `_to` and lock for `_lockDuration`


```solidity
function _createLock(uint256 _value, uint256 _lockDuration, bool _maxLockEnabled, address _to)
    internal
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_value`|`uint256`|Amount to deposit|
|`_lockDuration`|`uint256`|Number of seconds to lock tokens for (rounded down to nearest week)|
|`_maxLockEnabled`|`bool`||
|`_to`|`address`|Address to deposit|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 tokenId of the newly created veALCX|


### _findBlockEpoch

Binary search to estimate timestamp for block number


```solidity
function _findBlockEpoch(uint256 _block, uint256 maxEpoch) internal view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_block`|`uint256`|Block to find|
|`maxEpoch`|`uint256`|Don't go beyond this epoch|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Approximate timestamp for block|


### _balanceOfTokenAt

Get the voting power for `_tokenId` at timestamp


```solidity
function _balanceOfTokenAt(uint256 _tokenId, uint256 _time) internal view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token|
|`_time`|`uint256`|Timestamp to return voting power at|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|User voting power|


### _supplyAt

Calculate total voting power at some point in the past


```solidity
function _supplyAt(Point memory point, uint256 t) internal view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`point`|`Point`|The point (bias/slope) to start search from|
|`t`|`uint256`|Time to calculate the total voting power at|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Total voting power at that time|


### _tokenURI


```solidity
function _tokenURI(uint256 _tokenId, uint256 _balanceOf, uint256 _lockedEnd, uint256 _value)
    internal
    pure
    returns (string memory output);
```

### toString


```solidity
function toString(uint256 value) internal pure returns (string memory);
```

### _burn


```solidity
function _burn(uint256 _tokenId, uint256 _value) internal;
```

