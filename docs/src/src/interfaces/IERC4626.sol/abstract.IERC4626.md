# IERC4626
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/IERC4626.sol)

**Inherits:**
IERC20Metadata


## Functions
### asset

The address of the underlying ERC20 token used for
the Vault for accounting, depositing, and withdrawing.


```solidity
function asset() external view virtual returns (address);
```

### totalAssets

Total amount of the underlying asset that
is "managed" by Vault.


```solidity
function totalAssets() external view virtual returns (uint256);
```

### deposit

Mints `shares` Vault shares to `receiver` by
depositing exactly `assets` of underlying tokens.


```solidity
function deposit(uint256 assets, address receiver) external virtual returns (uint256 shares);
```

### mint

Mints exactly `shares` Vault shares to `receiver`
by depositing `assets` of underlying tokens.


```solidity
function mint(uint256 shares, address receiver) external virtual returns (uint256 assets);
```

### withdraw

Redeems `shares` from `owner` and sends `assets`
of underlying tokens to `receiver`.


```solidity
function withdraw(uint256 assets, address receiver, address owner) external virtual returns (uint256 shares);
```

### redeem

Redeems `shares` from `owner` and sends `assets`
of underlying tokens to `receiver`.


```solidity
function redeem(uint256 shares, address receiver, address owner) external virtual returns (uint256 assets);
```

### convertToShares

The amount of shares that the vault would
exchange for the amount of assets provided, in an
ideal scenario where all the conditions are met.


```solidity
function convertToShares(uint256 assets) external view virtual returns (uint256 shares);
```

### convertToAssets

The amount of assets that the vault would
exchange for the amount of shares provided, in an
ideal scenario where all the conditions are met.


```solidity
function convertToAssets(uint256 shares) external view virtual returns (uint256 assets);
```

### maxDeposit

Total number of underlying assets that can
be deposited by `owner` into the Vault, where `owner`
corresponds to the input parameter `receiver` of a
`deposit` call.


```solidity
function maxDeposit(address owner) external view virtual returns (uint256 maxAssets);
```

### previewDeposit

Allows an on-chain or off-chain user to simulate
the effects of their deposit at the current block, given
current on-chain conditions.


```solidity
function previewDeposit(uint256 assets) external view virtual returns (uint256 shares);
```

### maxMint

Total number of underlying shares that can be minted
for `owner`, where `owner` corresponds to the input
parameter `receiver` of a `mint` call.


```solidity
function maxMint(address owner) external view virtual returns (uint256 maxShares);
```

### previewMint

Allows an on-chain or off-chain user to simulate
the effects of their mint at the current block, given
current on-chain conditions.


```solidity
function previewMint(uint256 shares) external view virtual returns (uint256 assets);
```

### maxWithdraw

Total number of underlying assets that can be
withdrawn from the Vault by `owner`, where `owner`
corresponds to the input parameter of a `withdraw` call.


```solidity
function maxWithdraw(address owner) external view virtual returns (uint256 maxAssets);
```

### previewWithdraw

Allows an on-chain or off-chain user to simulate
the effects of their withdrawal at the current block,
given current on-chain conditions.


```solidity
function previewWithdraw(uint256 assets) external view virtual returns (uint256 shares);
```

### maxRedeem

Total number of underlying shares that can be
redeemed from the Vault by `owner`, where `owner` corresponds
to the input parameter of a `redeem` call.


```solidity
function maxRedeem(address owner) external view virtual returns (uint256 maxShares);
```

### previewRedeem

Allows an on-chain or off-chain user to simulate
the effects of their redeemption at the current block,
given current on-chain conditions.


```solidity
function previewRedeem(uint256 shares) external view virtual returns (uint256 assets);
```

## Events
### Deposit
`caller` has exchanged `assets` for `shares`, and transferred those `shares` to `owner`


```solidity
event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
```

### Withdraw
`caller` has exchanged `shares`, owned by `owner`, for
`assets`, and transferred those `assets` to `receiver`.


```solidity
event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);
```

