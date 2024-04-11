# IVotingEscrow
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/IVotingEscrow.sol)


## Functions
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


### BPT


```solidity
function BPT() external view returns (address);
```

### MULTIPLIER


```solidity
function MULTIPLIER() external view returns (uint256);
```

### MAXTIME


```solidity
function MAXTIME() external view returns (uint256);
```

### ALCX


```solidity
function ALCX() external view returns (address);
```

### distributor


```solidity
function distributor() external view returns (address);
```

### claimFeeBps


```solidity
function claimFeeBps() external view returns (uint256);
```

### fluxPerVeALCX


```solidity
function fluxPerVeALCX() external view returns (uint256);
```

### fluxMultiplier


```solidity
function fluxMultiplier() external view returns (uint256);
```

### EPOCH


```solidity
function EPOCH() external view returns (uint256);
```

### epoch


```solidity
function epoch() external view returns (uint256);
```

### lockEnd

Get timestamp when `_tokenId`'s lock finishes


```solidity
function lockEnd(uint256 tokenId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|ID of the token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Epoch time of the lock end|


### isMaxLocked

Check if token is max locked


```solidity
function isMaxLocked(uint256 tokenId) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|ID of the token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if token has max lock enabled|


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
function cooldownEnd(uint256 tokenId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|ID of the token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Epoch time of the cooldown end|


### getPointHistory


```solidity
function getPointHistory(uint256 loc) external view returns (Point memory);
```

### getUserPointHistory


```solidity
function getUserPointHistory(uint256 tokenId, uint256 loc) external view returns (Point memory);
```

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


### userPointEpoch


```solidity
function userPointEpoch(uint256 tokenId) external view returns (uint256);
```

### userFirstEpoch


```solidity
function userFirstEpoch(uint256 tokenId) external view returns (uint256);
```

### ownerOf

Returns the address of the owner of the token.


```solidity
function ownerOf(uint256 tokenId) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|ID of the token.|


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


### isApprovedOrOwner


```solidity
function isApprovedOrOwner(address, uint256) external view returns (bool);
```

### setVoter


```solidity
function setVoter(address voter) external;
```

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


### voting


```solidity
function voting(uint256 tokenId) external;
```

### abstain


```solidity
function abstain(uint256 tokenId) external;
```

### attach


```solidity
function attach(uint256 tokenId) external;
```

### detach


```solidity
function detach(uint256 tokenId) external;
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
function updateLock(uint256 tokenId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|ID of the token|


### depositFor

Deposit `_value` tokens for `_tokenId` and add to the lock

*Anyone (even a smart contract) can deposit for someone else, but
cannot extend their locktime and deposit for a brand new user*


```solidity
function depositFor(uint256 tokenId, uint256 value) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|ID of the token to deposit for|
|`value`|`uint256`|Amount to add to user's lock|


### balanceOfToken


```solidity
function balanceOfToken(uint256 tokenId) external view returns (uint256);
```

### balanceOfTokenAt


```solidity
function balanceOfTokenAt(uint256 _tokenId, uint256 _time) external view returns (uint256);
```

### claimableFlux

Amount of flux claimable at current epoch

*flux should accrue at the ragequit amount divided by the fluxMultiplier per epoch*


```solidity
function claimableFlux(uint256 tokenId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|ID of the token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Amount of claimable flux for the current epoch|


### startCooldown

Starts the cooldown for `_tokenId`

*If lock is not expired cooldown can only be started by burning FLUX*


```solidity
function startCooldown(uint256 tokenId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|ID of the token to start cooldown for|


### amountToRagequit

Amount of FLUX required to ragequit for a given token

*Amount to ragequit should be a function of the voting power*


```solidity
function amountToRagequit(uint256 tokenId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|ID of token to ragequit|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Amount of FLUX required to ragequit|


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


### totalSupplyAtT

Calculate total voting power

*Adheres to the ERC20 `totalSupply` interface for Aragon compatibility*


```solidity
function totalSupplyAtT(uint256 t) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`t`|`uint256`|Timestamp provided|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Total voting power|


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

### AdminUpdated

```solidity
event AdminUpdated(address admin);
```

### ClaimFeeUpdated

```solidity
event ClaimFeeUpdated(uint256 claimFee);
```

### VoterUpdated

```solidity
event VoterUpdated(address voter);
```

### RewardsDistributorUpdated

```solidity
event RewardsDistributorUpdated(address distributor);
```

### FluxMultiplierUpdated

```solidity
event FluxMultiplierUpdated(uint256 fluxMultiplier);
```

### FluxPerVeALCXUpdated

```solidity
event FluxPerVeALCXUpdated(uint256 fluxPerVeALCX);
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

### TreasuryUpdated

```solidity
event TreasuryUpdated(address indexed newTreasury);
```

## Structs
### Checkpoint
A checkpoint for marking delegated tokenIds from a given timestamp


```solidity
struct Checkpoint {
    uint256 timestamp;
    uint256[] tokenIds;
}
```

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
    uint256 amount;
    uint256 end;
    bool maxLockEnabled;
    uint256 cooldown;
}
```

## Enums
### DepositType

```solidity
enum DepositType {
    DEPOSIT_FOR_TYPE,
    CREATE_LOCK_TYPE,
    INCREASE_UNLOCK_TIME,
    MERGE_TYPE
}
```

