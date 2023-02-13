# VotingEscrow
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/VotingEscrow.sol)

**Inherits:**
IERC721, IERC721Metadata, IVotes

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
uint8 public constant decimals = 18;
```


### DOMAIN_TYPEHASH
The EIP-712 typehash for the contract's domain


```solidity
bytes32 public constant DOMAIN_TYPEHASH =
    keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
```


### DELEGATION_TYPEHASH
The EIP-712 typehash for the delegation struct used by the contract


```solidity
bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");
```


### ERC165_INTERFACE_ID
*ERC165 interface ID of ERC165*


```solidity
bytes4 internal constant ERC165_INTERFACE_ID = 0x01ffc9a7;
```


### ERC721_INTERFACE_ID
*ERC165 interface ID of ERC721*


```solidity
bytes4 internal constant ERC721_INTERFACE_ID = 0x80ac58cd;
```


### ERC721_METADATA_INTERFACE_ID
*ERC165 interface ID of ERC721Metadata*


```solidity
bytes4 internal constant ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;
```


### EPOCH

```solidity
uint256 public constant EPOCH = 2 weeks;
```


### MAX_DELEGATES

```solidity
uint256 public constant MAX_DELEGATES = 1024;
```


### WEEK

```solidity
uint256 internal constant WEEK = 1 weeks;
```


### MAXTIME

```solidity
uint256 internal constant MAXTIME = 365 days;
```


### MULTIPLIER

```solidity
uint256 internal constant MULTIPLIER = 26 ether;
```


### iMAXTIME

```solidity
int256 internal constant iMAXTIME = 365 days;
```


### iMULTIPLIER

```solidity
int256 internal constant iMULTIPLIER = 26 ether;
```


### tokenId
*Current count of token*


```solidity
uint256 internal tokenId;
```


### ALCX

```solidity
address public ALCX;
```


### FLUX

```solidity
address public FLUX;
```


### BPT

```solidity
address public BPT;
```


### rewardPool

```solidity
address public rewardPool;
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


### unclaimedFlux

```solidity
mapping(uint256 => uint256) public unclaimedFlux;
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


### supportedInterfaces
*Mapping of interface id to bool about whether or not it's supported*


```solidity
mapping(bytes4 => bool) internal supportedInterfaces;
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
constructor(address _bpt, address _alcx, address _flux, address _rewardPool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_bpt`|`address`|`BPT` token address|
|`_alcx`|`address`|`ALCX` token address|
|`_flux`|`address`|`FLUX` token address|
|`_rewardPool`|`address`||


### supportsInterface

Interface identification is specified in ERC-165.


```solidity
function supportsInterface(bytes4 _interfaceID) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_interfaceID`|`bytes4`|Id of the interface|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool Boolean result of provided interface|


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
|`_idx`|`uint256`|User epoch number|

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
|`_idx`|`uint256`|User epoch number|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Epoch time of the checkpoint|


### lockEnd

Get timestamp when `_tokenId`'s lock finishes


```solidity
function lockEnd(uint256 _tokenId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Epoch time of the lock end|


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
|`_tokenId`|`uint256`|ID of the token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Epoch time of the cooldown end|


### balanceOf

Returns the number of tokens owned by `_owner`.

*Throws if `_owner` is the zero address. tokens assigned to the zero address are considered invalid.*


```solidity
function balanceOf(address _owner) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_owner`|`address`|Address for whom to query the balance.|


### ownerOf

Returns the address of the owner of the token.


```solidity
function ownerOf(uint256 _tokenId) public view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token.|


### getApproved

Get the approved address for a single token.


```solidity
function getApproved(uint256 _tokenId) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token to query the approval of.|


### isApprovedForAll

Checks if `_operator` is an approved operator for `_owner`.


```solidity
function isApprovedForAll(address _owner, address _operator) external view returns (bool);
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


```solidity
function getPastVotes(address account, uint256 timestamp) public view returns (uint256);
```

### getPastTotalSupply


```solidity
function getPastTotalSupply(uint256 timestamp) external view returns (uint256);
```

### amountToRagequit

Amount of FLUX required to ragequit for a given token


```solidity
function amountToRagequit(uint256 _tokenId) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of token to ragequit|


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


```solidity
function claimableFlux(uint256 _tokenId) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Amount of claimable flux for the current epoch|


### balanceOfAtToken


```solidity
function balanceOfAtToken(uint256 _tokenId, uint256 _block) external view returns (uint256);
```

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


### totalSupplyAt

Calculate total voting power at some point in the past


```solidity
function totalSupplyAt(uint256 _block) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_block`|`uint256`|Block to calculate the total voting power at|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Total voting power at `_block`|


### transferFrom

*Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this token.
Throws if `_from` is not the current owner.
Throws if `_to` is the zero address.
Throws if `_tokenId` is not a valid token.*

*The caller is responsible to confirm that `_to` is capable of receiving tokens or else
they maybe be permanently lost.*


```solidity
function transferFrom(address _from, address _to, uint256 _tokenId) external;
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
function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) public;
```

### setVoter


```solidity
function setVoter(address _voter) external;
```

### setRewardsDistributor


```solidity
function setRewardsDistributor(address _distributor) external;
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
|`_tokenId`|`uint256`|ID of the token to deposit for|
|`_value`|`uint256`|Amount to add to user's lock|


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


### increaseAmount

Deposit `_value` additional tokens for `_tokenId` without modifying the unlock time


```solidity
function increaseAmount(uint256 _tokenId, uint256 _value) external nonreentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`||
|`_value`|`uint256`|Amount of tokens to deposit and add to the lock|


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

### accrueFlux

Accrue unclaimed flux for a given veALCX


```solidity
function accrueFlux(uint256 _tokenId, uint256 _amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token flux is being accrued to|
|`_amount`|`uint256`|Amount of flux being accrued|


### claimFlux

Claim unclaimed flux for a given veALCX

*flux can only be claimed after accrual*


```solidity
function claimFlux(uint256 _tokenId, uint256 _amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token flux is being accrued to|
|`_amount`|`uint256`|Amount of flux being claimed|


### startCooldown

Starts the cooldown for `_tokenId`

*If lock is not expired cooldown can only be started by burning FLUX*


```solidity
function startCooldown(uint256 _tokenId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token to start cooldown for|


### depositIntoRewardPool

Deposit amount into rewardPool

*Can only be called by governance*


```solidity
function depositIntoRewardPool(uint256 _amount) external;
```

### withdrawFromRewardPool

Withdraw amount from rewardPool

*Can only be called by governance*


```solidity
function withdrawFromRewardPool(uint256 _amount) external;
```

### updateRewardPool

Update the address of the rewardPool


```solidity
function updateRewardPool(address _newRewardPool) external;
```

### claimRewardPoolRewards

Claim rewards from the rewardPool


```solidity
function claimRewardPoolRewards() external;
```

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


### _claimFlux


```solidity
function _claimFlux(uint256 _tokenId, uint256 _amount) internal;
```

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

Exeute transfer of a token.

*Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
address for this token. (NOTE: `msg.sender` not allowed in internal function so pass `_sender`.)
Throws if `_to` is the zero address.
Throws if `_from` is not the current owner.
Throws if `_tokenId` is not a valid token.*


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


### _moveTokenDelegates


```solidity
function _moveTokenDelegates(address srcRep, address dstRep, uint256 _tokenId) internal;
```

### _findWhatCheckpointToWrite


```solidity
function _findWhatCheckpointToWrite(address account) internal view returns (uint32);
```

### _moveAllDelegates


```solidity
function _moveAllDelegates(address owner, address srcRep, address dstRep) internal;
```

### _delegate


```solidity
function _delegate(address delegator, address delegatee) internal;
```

### _checkpoint

differs from `_delegate()` in `Comp.sol` to use `delegates` override method to simulate auto-delegation

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


### _depositIntoRewardPool

Deposit amount into rewardPool


```solidity
function _depositIntoRewardPool(uint256 _amount) internal returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Amount to deposit|


### _withdrawFromRewardPool

Withdraw amount from rewardPool


```solidity
function _withdrawFromRewardPool(uint256 _amount) internal returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Amount to withdraw|


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


### _balanceOfToken

Get the current voting power for `_tokenId`

*Adheres to the ERC20 `balanceOf` interface for Aragon compatibility*


```solidity
function _balanceOfToken(uint256 _tokenId, uint256 _time) internal view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token|
|`_time`|`uint256`|Epoch time to return voting power at|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|User voting power|


### _balanceOfAtToken

Measure voting power of `_tokenId` at block height `_block`

*Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime*


```solidity
function _balanceOfAtToken(uint256 _tokenId, uint256 _block) internal view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token|
|`_block`|`uint256`|Block to calculate the voting power at|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Voting power|


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
function _burn(uint256 _tokenId) internal;
```

## Events
### Deposit

```solidity
event Deposit(
    address indexed provider,
    uint256 tokenId,
    uint256 value,
    uint256 indexed locktime,
    bool maxLockEnabled,
    DepositType depositType,
    uint256 ts
);
```

### Withdraw

```solidity
event Withdraw(address indexed provider, uint256 tokenId, uint256 value, uint256 ts);
```

### Supply

```solidity
event Supply(uint256 prevSupply, uint256 supply);
```

### Ragequit

```solidity
event Ragequit(address indexed provider, uint256 tokenId, uint256 ts);
```

### CooldownStarted

```solidity
event CooldownStarted(address indexed provider, uint256 tokenId, uint256 ts);
```

## Structs
### Point

```solidity
struct Point {
    int256 bias;
    int256 slope;
    uint256 ts;
    uint256 blk;
}
```

### LockedBalance

```solidity
struct LockedBalance {
    int256 amount;
    uint256 end;
    bool maxLockEnabled;
    uint256 cooldown;
}
```

### Checkpoint
A checkpoint for marking delegated tokenIds from a given timestamp


```solidity
struct Checkpoint {
    uint256 timestamp;
    uint256[] tokenIds;
}
```

## Enums
### DepositType

```solidity
enum DepositType {
    DEPOSIT_FOR_TYPE,
    CREATE_LOCK_TYPE,
    INCREASE_LOCK_AMOUNT,
    INCREASE_UNLOCK_TIME,
    MERGE_TYPE
}
```

