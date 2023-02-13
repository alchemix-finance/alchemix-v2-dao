# TokenUtils
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/libraries/TokenUtils.sol)

**Author:**
Alchemix Finance


## Functions
### expectDecimals

*A safe function to get the decimals of an ERC20 token.*

*Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.*


```solidity
function expectDecimals(address token) internal view returns (uint8);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The target token.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint8`|The amount of decimals of the token.|


### safeBalanceOf

*Gets the balance of tokens held by an account.*

*Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.*


```solidity
function safeBalanceOf(address token, address account) internal view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|  The token to check the balance of.|
|`account`|`address`|The address of the token holder.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The balance of the tokens held by an account.|


### safeTransfer

*Transfers tokens to another address.*

*Reverts with a {CallFailed} error if execution of the transfer failed or returns an unexpected value.*


```solidity
function safeTransfer(address token, address recipient, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|    The token to transfer.|
|`recipient`|`address`|The address of the recipient.|
|`amount`|`uint256`|   The amount of tokens to transfer.|


### safeApprove

*Approves tokens for the smart contract.*

*Reverts with a {CallFailed} error if execution of the approval fails or returns an unexpected value.*


```solidity
function safeApprove(address token, address spender, uint256 value) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|  The token to approve.|
|`spender`|`address`|The contract to spend the tokens.|
|`value`|`uint256`|  The amount of tokens to approve.|


### safeTransferFrom

*Transfer tokens from one address to another address.*

*Reverts with a {CallFailed} error if execution of the transfer fails or returns an unexpected value.*


```solidity
function safeTransferFrom(address token, address owner, address recipient, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|    The token to transfer.|
|`owner`|`address`|    The address of the owner.|
|`recipient`|`address`|The address of the recipient.|
|`amount`|`uint256`|   The amount of tokens to transfer.|


### safeMint

*Mints tokens to an address.*

*Reverts with a {CallFailed} error if execution of the mint fails or returns an unexpected value.*


```solidity
function safeMint(address token, address recipient, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|    The token to mint.|
|`recipient`|`address`|The address of the recipient.|
|`amount`|`uint256`|   The amount of tokens to mint.|


### safeBurn

*Burns tokens.
Reverts with a `CallFailed` error if execution of the burn fails or returns an unexpected value.*


```solidity
function safeBurn(address token, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`| The token to burn.|
|`amount`|`uint256`|The amount of tokens to burn.|


### safeBurnFrom

*Burns tokens from its total supply.*

*Reverts with a {CallFailed} error if execution of the burn fails or returns an unexpected value.*


```solidity
function safeBurnFrom(address token, address owner, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`| The token to burn.|
|`owner`|`address`| The owner of the tokens.|
|`amount`|`uint256`|The amount of tokens to burn.|


## Errors
### ERC20CallFailed
An error used to indicate that a call to an ERC20 contract failed.


```solidity
error ERC20CallFailed(address target, bool success, bytes data);
```

