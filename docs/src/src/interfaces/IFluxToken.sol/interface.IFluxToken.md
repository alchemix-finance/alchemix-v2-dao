# IFluxToken
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/IFluxToken.sol)

**Inherits:**
IERC20


## Functions
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


### setMinter

Set the address responsible for minting

*This function reverts if the caller does not have the minter role.*


```solidity
function setMinter(address _minter) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_minter`|`address`|Address that enables the minting of FLUX|


### mint

Mints tokens to a recipient.

*This function reverts if the caller does not have the minter role.*


```solidity
function mint(address _recipient, uint256 _amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_recipient`|`address`|the account to mint tokens to.|
|`_amount`|`uint256`|   the amount of tokens to mint.|


### nftClaim

Mints tokens to a recipient.

*This will revert after set claim period, if the NFT has already been claimed, or if the caller is not the owner of the NFT*

*Amount of FLUX minted is one year of potential FLUX rewards given the NFTs value.*


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

Given amount of eth, calculate how much FLUX it would earn in a year if it were deposited into veALCX


```solidity
function getClaimableFlux(uint256 _amount, address _nft) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|Amount to calculate claimable flux for|
|`_nft`|`address`|Which NFT to calculate claimable flux for|


## Events
### AdminUpdated

```solidity
event AdminUpdated(address admin);
```

