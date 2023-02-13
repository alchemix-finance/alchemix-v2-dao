# IVault
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/d8d0b0d485c418b8ae578e8607716a71a6b37bf6/src/interfaces/balancer/IVault.sol)

**Inherits:**
[ISignaturesValidator](/src/interfaces/helpers/ISignaturesValidator.sol/contract.ISignaturesValidator.md), [ITemporarilyPausable](/src/interfaces/helpers/ITemporarilyPausable.sol/contract.ITemporarilyPausable.md), [IAuthentication](/src/interfaces/helpers/IAuthentication.sol/contract.IAuthentication.md)

*Full external interface for the Vault core contract - no external or public methods exist in the contract that
don't override one of these declarations.*


## Functions
### getAuthorizer

*Returns the Vault's Authorizer.*


```solidity
function getAuthorizer() external view returns (IAuthorizer);
```

### setAuthorizer

*Sets a new Authorizer for the Vault. The caller must be allowed by the current Authorizer to do this.
Emits an `AuthorizerChanged` event.*


```solidity
function setAuthorizer(IAuthorizer newAuthorizer) external;
```

### hasApprovedRelayer

*Returns true if `user` has approved `relayer` to act as a relayer for them.*


```solidity
function hasApprovedRelayer(address user, address relayer) external view returns (bool);
```

### setRelayerApproval

*Allows `relayer` to act as a relayer for `sender` if `approved` is true, and disallows it otherwise.
Emits a `RelayerApprovalChanged` event.*


```solidity
function setRelayerApproval(address sender, address relayer, bool approved) external;
```

### getInternalBalance

*Returns `user`'s Internal Balance for a set of tokens.*


```solidity
function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);
```

### manageUserBalance

*Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
it lets integrators reuse a user's Vault allowance.
For each operation, if the caller is not `sender`, it must be an authorized relayer for them.*


```solidity
function manageUserBalance(UserBalanceOp[] memory ops) external payable;
```

### registerPool

*Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
changed.
The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
depending on the chosen specialization setting. This contract is known as the Pool's contract.
Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
multiple Pools may share the same contract.
Emits a `PoolRegistered` event.*


```solidity
function registerPool(PoolSpecialization specialization) external returns (bytes32);
```

### getPool

*Returns a Pool's contract address and specialization setting.*


```solidity
function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);
```

### registerTokens

*Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
exit by receiving registered tokens, and can only swap registered tokens.
Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
ascending order.
The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
expected to be highly secured smart contracts with sound design principles, and the decision to register an
Asset Manager should not be made lightly.
Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
different Asset Manager.
Emits a `TokensRegistered` event.*


```solidity
function registerTokens(bytes32 poolId, IERC20[] memory tokens, address[] memory assetManagers) external;
```

### deregisterTokens

*Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
must be deregistered in the same `deregisterTokens` call.
A deregistered token can be re-registered later on, possibly with a different Asset Manager.
Emits a `TokensDeregistered` event.*


```solidity
function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;
```

### getPoolTokenInfo

*Returns detailed information for a Pool's registered token.
`cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
equals the sum of `cash` and `managed`.
Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
`managed` or `total` balance to be greater than 2^112 - 1.
`lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
change for this purpose, and will update `lastChangeBlock`.
`assetManager` is the Pool's token Asset Manager.*


```solidity
function getPoolTokenInfo(bytes32 poolId, IERC20 token)
    external
    view
    returns (uint256 cash, uint256 managed, uint256 lastChangeBlock, address assetManager);
```

### getPoolTokens

*Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
the tokens' `balances` changed.
The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
order as passed to `registerTokens`.
Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
instead.*


```solidity
function getPoolTokens(bytes32 poolId)
    external
    view
    returns (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);
```

### joinPool

*Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
Pool shares.
If the caller is not `sender`, it must be an authorized relayer for them.
The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
these maximums.
If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
back to the caller (not the sender, which is important for relayers).
`assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
`assets` array might not be sorted. Pools with no registered tokens cannot be joined.
If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
withdrawn from Internal Balance: attempting to do so will trigger a revert.
This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
their own custom logic. This typically requires additional information from the user (such as the expected number
of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
directly to the Pool's contract, as is `recipient`.
Emits a `PoolBalanceChanged` event.*


```solidity
function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request) external payable;
```

### exitPool

*Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
`getPoolTokenInfo`).
If the caller is not `sender`, it must be an authorized relayer for them.
The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
it just enforces these minimums.
If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
`assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
do so will trigger a revert.
`minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
`tokens` array. This array must match the Pool's registered tokens.
This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
their own custom logic. This typically requires additional information from the user (such as the expected number
of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
passed directly to the Pool's contract.
Emits a `PoolBalanceChanged` event.*


```solidity
function exitPool(bytes32 poolId, address sender, address payable recipient, ExitPoolRequest memory request) external;
```

### swap

*Performs a swap with a single Pool.
If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
taken from the Pool, which must be greater than or equal to `limit`.
If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
sent to the Pool, which must be less than or equal to `limit`.
Internal Balance usage and the recipient are determined by the `funds` struct.
Emits a `Swap` event.*


```solidity
function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline)
    external
    payable
    returns (uint256);
```

### batchSwap

*Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
the amount of tokens sent to or received from the Pool, depending on the `kind` value.
Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
the same index in the `assets` array.
Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
`amountOut` depending on the swap kind.
Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
or unwrapped from WETH by the Vault.
Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
the minimum or maximum amount of each token the vault is allowed to transfer.
`batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
equivalent `swap` call.
Emits `Swap` events.*


```solidity
function batchSwap(
    SwapKind kind,
    BatchSwapStep[] memory swaps,
    IAsset[] memory assets,
    FundManagement memory funds,
    int256[] memory limits,
    uint256 deadline
) external payable returns (int256[] memory);
```

### queryBatchSwap

*Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
receives are the same that an equivalent `batchSwap` call would receive.
Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
approve them for the Vault, or even know a user's address.
Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
eth_call instead of eth_sendTransaction.*


```solidity
function queryBatchSwap(
    SwapKind kind,
    BatchSwapStep[] memory swaps,
    IAsset[] memory assets,
    FundManagement memory funds
) external returns (int256[] memory assetDeltas);
```

### flashLoan

*Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
and then reverting unless the tokens plus a proportional protocol fee have been returned.
The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
for each token contract. `tokens` must be sorted in ascending order.
The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
`receiveFlashLoan` call.
Emits `FlashLoan` events.*


```solidity
function flashLoan(
    IFlashLoanRecipient recipient,
    IERC20[] memory tokens,
    uint256[] memory amounts,
    bytes memory userData
) external;
```

### managePoolBalance

*Performs a set of Pool balance operations, which may be either withdrawals, deposits or updates.
Pool Balance management features batching, which means a single contract call can be used to perform multiple
operations of different kinds, with different Pools and tokens, at once.
For each operation, the caller must be registered as the Asset Manager for `token` in `poolId`.*


```solidity
function managePoolBalance(PoolBalanceOp[] memory ops) external;
```

### getProtocolFeesCollector

*Returns the current protocol fee module.*


```solidity
function getProtocolFeesCollector() external view returns (IProtocolFeesCollector);
```

### setPaused

*Safety mechanism to pause most Vault operations in the event of an emergency - typically detection of an
error in some part of the system.
The Vault can only be paused during an initial time period, after which pausing is forever disabled.
While the contract is paused, the following features are disabled:
- depositing and transferring internal balance
- transferring external balance (using the Vault's allowance)
- swaps
- joining Pools
- Asset Manager interactions
Internal Balance can still be withdrawn, and Pools exited.*


```solidity
function setPaused(bool paused) external;
```

### WETH

*Returns the Vault's WETH instance.*


```solidity
function WETH() external view returns (IWETH);
```

## Events
### AuthorizerChanged
*Emitted when a new authorizer is set by `setAuthorizer`.*


```solidity
event AuthorizerChanged(IAuthorizer indexed newAuthorizer);
```

### RelayerApprovalChanged
*Emitted every time a relayer is approved or disapproved by `setRelayerApproval`.*


```solidity
event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);
```

### InternalBalanceChanged
*Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
interacting with Pools using Internal Balance.
Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
address.*


```solidity
event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);
```

### ExternalBalanceTransfer
*Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.*


```solidity
event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);
```

### PoolRegistered
*Emitted when a Pool is registered by calling `registerPool`.*


```solidity
event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);
```

### TokensRegistered
*Emitted when a Pool registers tokens by calling `registerTokens`.*


```solidity
event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);
```

### TokensDeregistered
*Emitted when a Pool deregisters tokens by calling `deregisterTokens`.*


```solidity
event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);
```

### PoolBalanceChanged
*Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.*


```solidity
event PoolBalanceChanged(
    bytes32 indexed poolId,
    address indexed liquidityProvider,
    IERC20[] tokens,
    int256[] deltas,
    uint256[] protocolFeeAmounts
);
```

### Swap
*Emitted for each individual swap performed by `swap` or `batchSwap`.*


```solidity
event Swap(
    bytes32 indexed poolId, IERC20 indexed tokenIn, IERC20 indexed tokenOut, uint256 amountIn, uint256 amountOut
);
```

### FlashLoan
*Emitted for each individual flash loan performed by `flashLoan`.*


```solidity
event FlashLoan(IFlashLoanRecipient indexed recipient, IERC20 indexed token, uint256 amount, uint256 feeAmount);
```

### PoolBalanceManaged
*Emitted when a Pool's token Asset Manager alters its balance via `managePoolBalance`.*


```solidity
event PoolBalanceManaged(
    bytes32 indexed poolId, address indexed assetManager, IERC20 indexed token, int256 cashDelta, int256 managedDelta
);
```

## Structs
### UserBalanceOp
*Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
without manual WETH wrapping or unwrapping.*


```solidity
struct UserBalanceOp {
    UserBalanceOpKind kind;
    IAsset asset;
    uint256 amount;
    address sender;
    address payable recipient;
}
```

### JoinPoolRequest

```solidity
struct JoinPoolRequest {
    IAsset[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
}
```

### ExitPoolRequest

```solidity
struct ExitPoolRequest {
    IAsset[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
}
```

### SingleSwap
*Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
the `kind` value.
`assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
used to extend swap behavior.*


```solidity
struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    IAsset assetIn;
    IAsset assetOut;
    uint256 amount;
    bytes userData;
}
```

### BatchSwapStep
*Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
`assets` array passed to that function, and ETH assets are converted to WETH.
If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
from the previous swap, depending on the swap kind.
The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
used to extend swap behavior.*


```solidity
struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
}
```

### FundManagement
*All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
`recipient` account.
If the caller is not `sender`, it must be an authorized relayer for them.
If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
`joinPool`.
If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
transferred. This matches the behavior of `exitPool`.
Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
revert.*


```solidity
struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
}
```

### PoolBalanceOp

```solidity
struct PoolBalanceOp {
    PoolBalanceOpKind kind;
    bytes32 poolId;
    IERC20 token;
    uint256 amount;
}
```

## Enums
### UserBalanceOpKind

```solidity
enum UserBalanceOpKind {
    DEPOSIT_INTERNAL,
    WITHDRAW_INTERNAL,
    TRANSFER_INTERNAL,
    TRANSFER_EXTERNAL
}
```

### PoolSpecialization

```solidity
enum PoolSpecialization {
    GENERAL,
    MINIMAL_SWAP_INFO,
    TWO_TOKEN
}
```

### PoolBalanceChangeKind

```solidity
enum PoolBalanceChangeKind {
    JOIN,
    EXIT
}
```

### SwapKind

```solidity
enum SwapKind {
    GIVEN_IN,
    GIVEN_OUT
}
```

### PoolBalanceOpKind
Withdrawals decrease the Pool's cash, but increase its managed balance, leaving the total balance unchanged.
Deposits increase the Pool's cash, but decrease its managed balance, leaving the total balance unchanged.
Updates don't affect the Pool's cash balance, but because the managed balance changes, it does alter the total.
The external amount can be either increased or decreased by this call (i.e., reporting a gain or a loss).


```solidity
enum PoolBalanceOpKind {
    WITHDRAW,
    DEPOSIT,
    UPDATE
}
```

