# FluxToken
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/FluxToken.sol)

**Inherits:**
ERC20, [IFluxToken](/src/interfaces/IFluxToken.sol/interface.IFluxToken.md)

Contract for the Alchemix DAO Flux token


## State Variables
### minter
*The address which enables the minting of tokens.*


```solidity
address public minter;
```


### voter

```solidity
address public voter;
```


### veALCX

```solidity
address public veALCX;
```


### alchemechNFT

```solidity
address public alchemechNFT;
```


### patronNFT

```solidity
address public patronNFT;
```


### admin

```solidity
address public admin;
```


### pendingAdmin

```solidity
address public pendingAdmin;
```


### deployDate

```solidity
uint256 public deployDate;
```


### alchemechMultiplier

```solidity
uint256 public alchemechMultiplier = 5;
```


### bptMultiplier

```solidity
uint256 public bptMultiplier = 40;
```


### oneYear

```solidity
uint256 public immutable oneYear = 365 days;
```


### BPS

```solidity
uint256 internal immutable BPS = 10_000;
```


### unclaimedFlux

```solidity
mapping(uint256 => uint256) public unclaimedFlux;
```


### claimed

```solidity
mapping(address => mapping(uint256 => bool)) public claimed;
```


## Functions
### constructor


```solidity
constructor(address _minter);
```

### onlyMinter

*Modifier which checks that the caller has the minter role.*


```solidity
modifier onlyMinter();
```

### setAdmin

Set the address responsible for administration

*This function reverts if the caller does not have the admin role.*


```solidity
function setAdmin(address _admin) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_admin`|`address`|Address that enables the administration of FLUX|


### acceptAdmin

Accept the address responsible for administration

*This function reverts if the caller does not have the pendingAdmin role.*


```solidity
function acceptAdmin() external;
```

### setVoter

Set the voting contract address

*This function reverts if the caller does not have the admin role.*


```solidity
function setVoter(address _voter) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_voter`|`address`|Voter contract address|


### setVeALCX

Set the veALCX contract address

*This function reverts if the caller does not have the admin role.*


```solidity
function setVeALCX(address _veALCX) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_veALCX`|`address`|veALCX contract address|


### setAlchemechNFT


```solidity
function setAlchemechNFT(address _alchemechNFT) external;
```

### setPatronNFT


```solidity
function setPatronNFT(address _patronNFT) external;
```

### setNftMultiplier


```solidity
function setNftMultiplier(uint256 _nftMultiplier) external;
```

### setBptMultiplier


```solidity
function setBptMultiplier(uint256 _bptMultiplier) external;
```

### setMinter

Set the address responsible for minting

*This function reverts if the caller does not have the minter role.*


```solidity
function setMinter(address _minter) external onlyMinter;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_minter`|`address`|Address that enables the minting of FLUX|


### mint

Mints tokens to a recipient.

*This function reverts if the caller does not have the minter role.*


```solidity
function mint(address _recipient, uint256 _amount) external onlyMinter;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_recipient`|`address`|the account to mint tokens to.|
|`_amount`|`uint256`|   the amount of tokens to mint.|


### nftClaim

Mints tokens to a recipient.

*This will revert after set claim period, if the NFT has already been claimed, or if the caller is not the owner of the NFT*


```solidity
function nftClaim(address _nft, uint256 _tokenId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_nft`|`address`|NFT contract address to claim from.|
|`_tokenId`|`uint256`|NFT tokenId to claim from.|


### burnFrom

*Burns `amount` tokens from `account`, deducting from the caller's allowance.*


```solidity
function burnFrom(address _account, uint256 _amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_account`|`address`|The address the burn tokens from.|
|`_amount`|`uint256`| The amount of tokens to burn.|


### getUnclaimedFlux

Get the amount of unclaimed flux for a given veALCX tokenId


```solidity
function getUnclaimedFlux(uint256 _tokenId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token to get unclaimed flux for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Amount of unclaimed flux|


### mergeFlux

Merge the unclaimed flux from one token into another


```solidity
function mergeFlux(uint256 _fromTokenId, uint256 _toTokenId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_fromTokenId`|`uint256`|The token to merge from|
|`_toTokenId`|`uint256`|  The token to merge to|


### accrueFlux

Accrue unclaimed flux for a given veALCX


```solidity
function accrueFlux(uint256 _tokenId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token flux is being accrued to|


### updateFlux

Update unclaimed flux balance for a given veALCX


```solidity
function updateFlux(uint256 _tokenId, uint256 _amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token flux is being updated for|
|`_amount`|`uint256`|Amount of flux being used|


### claimFlux

Claim unclaimed flux for a given token


```solidity
function claimFlux(uint256 _tokenId, uint256 _amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|ID of the token flux is being claimed for|
|`_amount`|`uint256`|Amount of flux being claimed|


### getClaimableFlux


```solidity
function getClaimableFlux(uint256 _amount, address _nft) public view returns (uint256 claimableFlux);
```

### _calculateBPT


```solidity
function _calculateBPT(uint256 _amount) public view returns (uint256 bptOut);
```

