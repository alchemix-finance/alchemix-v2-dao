# IVotingEscrow
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/IVotingEscrow.sol)


## Functions
### BPT


```solidity
function BPT() external view returns (address);
```

### ALCX


```solidity
function ALCX() external view returns (address);
```

### claimFeeBps


```solidity
function claimFeeBps() external view returns (uint256);
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


```solidity
function lockEnd(uint256 tokenId) external view returns (uint256);
```

### pointHistory


```solidity
function pointHistory(uint256 loc) external view returns (Point memory);
```

### userPointHistory


```solidity
function userPointHistory(uint256 tokenId, uint256 loc) external view returns (Point memory);
```

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


### userPointEpoch


```solidity
function userPointEpoch(uint256 tokenId) external view returns (uint256);
```

### userFirstEpoch


```solidity
function userFirstEpoch(uint256 tokenId) external view returns (uint256);
```

### ownerOf


```solidity
function ownerOf(uint256) external view returns (address);
```

### isApprovedOrOwner


```solidity
function isApprovedOrOwner(address, uint256) external view returns (bool);
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


### createLockFor

Deposit `_value` tokens for `_to` and lock for `_lockDuration`


```solidity
function createLockFor(uint256 _value, uint256 _lockDuration, address _maxLockEnabled, address _to)
    external
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_value`|`uint256`|Amount to deposit|
|`_lockDuration`|`uint256`|Number of seconds to lock tokens for (rounded down to nearest week)|
|`_maxLockEnabled`|`address`|Is max lock enabled|
|`_to`|`address`|Address to deposit|


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


### accrueFlux

Accrue unclaimed flux for a given veALCX


```solidity
function accrueFlux(uint256 tokenId, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|ID of the token flux is being accrued to|
|`amount`|`uint256`|Amount of flux being accrued|


### claimFlux

Claim unclaimed flux for a given veALCX

*flux can be claimed after accrual*


```solidity
function claimFlux(uint256 tokenId, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|ID of the token flux is being accrued to|
|`amount`|`uint256`|Amount of flux being claimed|


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


```solidity
function amountToRagequit(uint256 tokenId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|ID of token to ragequit|


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

