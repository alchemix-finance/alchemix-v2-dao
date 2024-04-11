# Errors
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/interfaces/balancer/BalancerErrors.sol)


## State Variables
### ADD_OVERFLOW

```solidity
uint256 internal constant ADD_OVERFLOW = 0;
```


### SUB_OVERFLOW

```solidity
uint256 internal constant SUB_OVERFLOW = 1;
```


### SUB_UNDERFLOW

```solidity
uint256 internal constant SUB_UNDERFLOW = 2;
```


### MUL_OVERFLOW

```solidity
uint256 internal constant MUL_OVERFLOW = 3;
```


### ZERO_DIVISION

```solidity
uint256 internal constant ZERO_DIVISION = 4;
```


### DIV_INTERNAL

```solidity
uint256 internal constant DIV_INTERNAL = 5;
```


### X_OUT_OF_BOUNDS

```solidity
uint256 internal constant X_OUT_OF_BOUNDS = 6;
```


### Y_OUT_OF_BOUNDS

```solidity
uint256 internal constant Y_OUT_OF_BOUNDS = 7;
```


### PRODUCT_OUT_OF_BOUNDS

```solidity
uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
```


### INVALID_EXPONENT

```solidity
uint256 internal constant INVALID_EXPONENT = 9;
```


### OUT_OF_BOUNDS

```solidity
uint256 internal constant OUT_OF_BOUNDS = 100;
```


### UNSORTED_ARRAY

```solidity
uint256 internal constant UNSORTED_ARRAY = 101;
```


### UNSORTED_TOKENS

```solidity
uint256 internal constant UNSORTED_TOKENS = 102;
```


### INPUT_LENGTH_MISMATCH

```solidity
uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
```


### ZERO_TOKEN

```solidity
uint256 internal constant ZERO_TOKEN = 104;
```


### MIN_TOKENS

```solidity
uint256 internal constant MIN_TOKENS = 200;
```


### MAX_TOKENS

```solidity
uint256 internal constant MAX_TOKENS = 201;
```


### MAX_SWAP_FEE_PERCENTAGE

```solidity
uint256 internal constant MAX_SWAP_FEE_PERCENTAGE = 202;
```


### MIN_SWAP_FEE_PERCENTAGE

```solidity
uint256 internal constant MIN_SWAP_FEE_PERCENTAGE = 203;
```


### MINIMUM_BPT

```solidity
uint256 internal constant MINIMUM_BPT = 204;
```


### CALLER_NOT_VAULT

```solidity
uint256 internal constant CALLER_NOT_VAULT = 205;
```


### UNINITIALIZED

```solidity
uint256 internal constant UNINITIALIZED = 206;
```


### BPT_IN_MAX_AMOUNT

```solidity
uint256 internal constant BPT_IN_MAX_AMOUNT = 207;
```


### BPT_OUT_MIN_AMOUNT

```solidity
uint256 internal constant BPT_OUT_MIN_AMOUNT = 208;
```


### EXPIRED_PERMIT

```solidity
uint256 internal constant EXPIRED_PERMIT = 209;
```


### NOT_TWO_TOKENS

```solidity
uint256 internal constant NOT_TWO_TOKENS = 210;
```


### DISABLED

```solidity
uint256 internal constant DISABLED = 211;
```


### MIN_AMP

```solidity
uint256 internal constant MIN_AMP = 300;
```


### MAX_AMP

```solidity
uint256 internal constant MAX_AMP = 301;
```


### MIN_WEIGHT

```solidity
uint256 internal constant MIN_WEIGHT = 302;
```


### MAX_STABLE_TOKENS

```solidity
uint256 internal constant MAX_STABLE_TOKENS = 303;
```


### MAX_IN_RATIO

```solidity
uint256 internal constant MAX_IN_RATIO = 304;
```


### MAX_OUT_RATIO

```solidity
uint256 internal constant MAX_OUT_RATIO = 305;
```


### MIN_BPT_IN_FOR_TOKEN_OUT

```solidity
uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 306;
```


### MAX_OUT_BPT_FOR_TOKEN_IN

```solidity
uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 307;
```


### NORMALIZED_WEIGHT_INVARIANT

```solidity
uint256 internal constant NORMALIZED_WEIGHT_INVARIANT = 308;
```


### INVALID_TOKEN

```solidity
uint256 internal constant INVALID_TOKEN = 309;
```


### UNHANDLED_JOIN_KIND

```solidity
uint256 internal constant UNHANDLED_JOIN_KIND = 310;
```


### ZERO_INVARIANT

```solidity
uint256 internal constant ZERO_INVARIANT = 311;
```


### ORACLE_INVALID_SECONDS_QUERY

```solidity
uint256 internal constant ORACLE_INVALID_SECONDS_QUERY = 312;
```


### ORACLE_NOT_INITIALIZED

```solidity
uint256 internal constant ORACLE_NOT_INITIALIZED = 313;
```


### ORACLE_QUERY_TOO_OLD

```solidity
uint256 internal constant ORACLE_QUERY_TOO_OLD = 314;
```


### ORACLE_INVALID_INDEX

```solidity
uint256 internal constant ORACLE_INVALID_INDEX = 315;
```


### ORACLE_BAD_SECS

```solidity
uint256 internal constant ORACLE_BAD_SECS = 316;
```


### AMP_END_TIME_TOO_CLOSE

```solidity
uint256 internal constant AMP_END_TIME_TOO_CLOSE = 317;
```


### AMP_ONGOING_UPDATE

```solidity
uint256 internal constant AMP_ONGOING_UPDATE = 318;
```


### AMP_RATE_TOO_HIGH

```solidity
uint256 internal constant AMP_RATE_TOO_HIGH = 319;
```


### AMP_NO_ONGOING_UPDATE

```solidity
uint256 internal constant AMP_NO_ONGOING_UPDATE = 320;
```


### STABLE_INVARIANT_DIDNT_CONVERGE

```solidity
uint256 internal constant STABLE_INVARIANT_DIDNT_CONVERGE = 321;
```


### STABLE_GET_BALANCE_DIDNT_CONVERGE

```solidity
uint256 internal constant STABLE_GET_BALANCE_DIDNT_CONVERGE = 322;
```


### RELAYER_NOT_CONTRACT

```solidity
uint256 internal constant RELAYER_NOT_CONTRACT = 323;
```


### BASE_POOL_RELAYER_NOT_CALLED

```solidity
uint256 internal constant BASE_POOL_RELAYER_NOT_CALLED = 324;
```


### REBALANCING_RELAYER_REENTERED

```solidity
uint256 internal constant REBALANCING_RELAYER_REENTERED = 325;
```


### GRADUAL_UPDATE_TIME_TRAVEL

```solidity
uint256 internal constant GRADUAL_UPDATE_TIME_TRAVEL = 326;
```


### SWAPS_DISABLED

```solidity
uint256 internal constant SWAPS_DISABLED = 327;
```


### CALLER_IS_NOT_LBP_OWNER

```solidity
uint256 internal constant CALLER_IS_NOT_LBP_OWNER = 328;
```


### PRICE_RATE_OVERFLOW

```solidity
uint256 internal constant PRICE_RATE_OVERFLOW = 329;
```


### INVALID_JOIN_EXIT_KIND_WHILE_SWAPS_DISABLED

```solidity
uint256 internal constant INVALID_JOIN_EXIT_KIND_WHILE_SWAPS_DISABLED = 330;
```


### WEIGHT_CHANGE_TOO_FAST

```solidity
uint256 internal constant WEIGHT_CHANGE_TOO_FAST = 331;
```


### LOWER_GREATER_THAN_UPPER_TARGET

```solidity
uint256 internal constant LOWER_GREATER_THAN_UPPER_TARGET = 332;
```


### UPPER_TARGET_TOO_HIGH

```solidity
uint256 internal constant UPPER_TARGET_TOO_HIGH = 333;
```


### UNHANDLED_BY_LINEAR_POOL

```solidity
uint256 internal constant UNHANDLED_BY_LINEAR_POOL = 334;
```


### OUT_OF_TARGET_RANGE

```solidity
uint256 internal constant OUT_OF_TARGET_RANGE = 335;
```


### UNHANDLED_EXIT_KIND

```solidity
uint256 internal constant UNHANDLED_EXIT_KIND = 336;
```


### UNAUTHORIZED_EXIT

```solidity
uint256 internal constant UNAUTHORIZED_EXIT = 337;
```


### MAX_MANAGEMENT_SWAP_FEE_PERCENTAGE

```solidity
uint256 internal constant MAX_MANAGEMENT_SWAP_FEE_PERCENTAGE = 338;
```


### UNHANDLED_BY_MANAGED_POOL

```solidity
uint256 internal constant UNHANDLED_BY_MANAGED_POOL = 339;
```


### UNHANDLED_BY_PHANTOM_POOL

```solidity
uint256 internal constant UNHANDLED_BY_PHANTOM_POOL = 340;
```


### TOKEN_DOES_NOT_HAVE_RATE_PROVIDER

```solidity
uint256 internal constant TOKEN_DOES_NOT_HAVE_RATE_PROVIDER = 341;
```


### INVALID_INITIALIZATION

```solidity
uint256 internal constant INVALID_INITIALIZATION = 342;
```


### OUT_OF_NEW_TARGET_RANGE

```solidity
uint256 internal constant OUT_OF_NEW_TARGET_RANGE = 343;
```


### FEATURE_DISABLED

```solidity
uint256 internal constant FEATURE_DISABLED = 344;
```


### UNINITIALIZED_POOL_CONTROLLER

```solidity
uint256 internal constant UNINITIALIZED_POOL_CONTROLLER = 345;
```


### SET_SWAP_FEE_DURING_FEE_CHANGE

```solidity
uint256 internal constant SET_SWAP_FEE_DURING_FEE_CHANGE = 346;
```


### SET_SWAP_FEE_PENDING_FEE_CHANGE

```solidity
uint256 internal constant SET_SWAP_FEE_PENDING_FEE_CHANGE = 347;
```


### CHANGE_TOKENS_DURING_WEIGHT_CHANGE

```solidity
uint256 internal constant CHANGE_TOKENS_DURING_WEIGHT_CHANGE = 348;
```


### CHANGE_TOKENS_PENDING_WEIGHT_CHANGE

```solidity
uint256 internal constant CHANGE_TOKENS_PENDING_WEIGHT_CHANGE = 349;
```


### MAX_WEIGHT

```solidity
uint256 internal constant MAX_WEIGHT = 350;
```


### UNAUTHORIZED_JOIN

```solidity
uint256 internal constant UNAUTHORIZED_JOIN = 351;
```


### MAX_MANAGEMENT_AUM_FEE_PERCENTAGE

```solidity
uint256 internal constant MAX_MANAGEMENT_AUM_FEE_PERCENTAGE = 352;
```


### FRACTIONAL_TARGET

```solidity
uint256 internal constant FRACTIONAL_TARGET = 353;
```


### ADD_OR_REMOVE_BPT

```solidity
uint256 internal constant ADD_OR_REMOVE_BPT = 354;
```


### INVALID_CIRCUIT_BREAKER_BOUNDS

```solidity
uint256 internal constant INVALID_CIRCUIT_BREAKER_BOUNDS = 355;
```


### CIRCUIT_BREAKER_TRIPPED

```solidity
uint256 internal constant CIRCUIT_BREAKER_TRIPPED = 356;
```


### REENTRANCY

```solidity
uint256 internal constant REENTRANCY = 400;
```


### SENDER_NOT_ALLOWED

```solidity
uint256 internal constant SENDER_NOT_ALLOWED = 401;
```


### PAUSED

```solidity
uint256 internal constant PAUSED = 402;
```


### PAUSE_WINDOW_EXPIRED

```solidity
uint256 internal constant PAUSE_WINDOW_EXPIRED = 403;
```


### MAX_PAUSE_WINDOW_DURATION

```solidity
uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 404;
```


### MAX_BUFFER_PERIOD_DURATION

```solidity
uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 405;
```


### INSUFFICIENT_BALANCE

```solidity
uint256 internal constant INSUFFICIENT_BALANCE = 406;
```


### INSUFFICIENT_ALLOWANCE

```solidity
uint256 internal constant INSUFFICIENT_ALLOWANCE = 407;
```


### ERC20_TRANSFER_FROM_ZERO_ADDRESS

```solidity
uint256 internal constant ERC20_TRANSFER_FROM_ZERO_ADDRESS = 408;
```


### ERC20_TRANSFER_TO_ZERO_ADDRESS

```solidity
uint256 internal constant ERC20_TRANSFER_TO_ZERO_ADDRESS = 409;
```


### ERC20_MINT_TO_ZERO_ADDRESS

```solidity
uint256 internal constant ERC20_MINT_TO_ZERO_ADDRESS = 410;
```


### ERC20_BURN_FROM_ZERO_ADDRESS

```solidity
uint256 internal constant ERC20_BURN_FROM_ZERO_ADDRESS = 411;
```


### ERC20_APPROVE_FROM_ZERO_ADDRESS

```solidity
uint256 internal constant ERC20_APPROVE_FROM_ZERO_ADDRESS = 412;
```


### ERC20_APPROVE_TO_ZERO_ADDRESS

```solidity
uint256 internal constant ERC20_APPROVE_TO_ZERO_ADDRESS = 413;
```


### ERC20_TRANSFER_EXCEEDS_ALLOWANCE

```solidity
uint256 internal constant ERC20_TRANSFER_EXCEEDS_ALLOWANCE = 414;
```


### ERC20_DECREASED_ALLOWANCE_BELOW_ZERO

```solidity
uint256 internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = 415;
```


### ERC20_TRANSFER_EXCEEDS_BALANCE

```solidity
uint256 internal constant ERC20_TRANSFER_EXCEEDS_BALANCE = 416;
```


### ERC20_BURN_EXCEEDS_ALLOWANCE

```solidity
uint256 internal constant ERC20_BURN_EXCEEDS_ALLOWANCE = 417;
```


### SAFE_ERC20_CALL_FAILED

```solidity
uint256 internal constant SAFE_ERC20_CALL_FAILED = 418;
```


### ADDRESS_INSUFFICIENT_BALANCE

```solidity
uint256 internal constant ADDRESS_INSUFFICIENT_BALANCE = 419;
```


### ADDRESS_CANNOT_SEND_VALUE

```solidity
uint256 internal constant ADDRESS_CANNOT_SEND_VALUE = 420;
```


### SAFE_CAST_VALUE_CANT_FIT_INT256

```solidity
uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_INT256 = 421;
```


### GRANT_SENDER_NOT_ADMIN

```solidity
uint256 internal constant GRANT_SENDER_NOT_ADMIN = 422;
```


### REVOKE_SENDER_NOT_ADMIN

```solidity
uint256 internal constant REVOKE_SENDER_NOT_ADMIN = 423;
```


### RENOUNCE_SENDER_NOT_ALLOWED

```solidity
uint256 internal constant RENOUNCE_SENDER_NOT_ALLOWED = 424;
```


### BUFFER_PERIOD_EXPIRED

```solidity
uint256 internal constant BUFFER_PERIOD_EXPIRED = 425;
```


### CALLER_IS_NOT_OWNER

```solidity
uint256 internal constant CALLER_IS_NOT_OWNER = 426;
```


### NEW_OWNER_IS_ZERO

```solidity
uint256 internal constant NEW_OWNER_IS_ZERO = 427;
```


### CODE_DEPLOYMENT_FAILED

```solidity
uint256 internal constant CODE_DEPLOYMENT_FAILED = 428;
```


### CALL_TO_NON_CONTRACT

```solidity
uint256 internal constant CALL_TO_NON_CONTRACT = 429;
```


### LOW_LEVEL_CALL_FAILED

```solidity
uint256 internal constant LOW_LEVEL_CALL_FAILED = 430;
```


### NOT_PAUSED

```solidity
uint256 internal constant NOT_PAUSED = 431;
```


### ADDRESS_ALREADY_ALLOWLISTED

```solidity
uint256 internal constant ADDRESS_ALREADY_ALLOWLISTED = 432;
```


### ADDRESS_NOT_ALLOWLISTED

```solidity
uint256 internal constant ADDRESS_NOT_ALLOWLISTED = 433;
```


### ERC20_BURN_EXCEEDS_BALANCE

```solidity
uint256 internal constant ERC20_BURN_EXCEEDS_BALANCE = 434;
```


### INVALID_OPERATION

```solidity
uint256 internal constant INVALID_OPERATION = 435;
```


### CODEC_OVERFLOW

```solidity
uint256 internal constant CODEC_OVERFLOW = 436;
```


### IN_RECOVERY_MODE

```solidity
uint256 internal constant IN_RECOVERY_MODE = 437;
```


### NOT_IN_RECOVERY_MODE

```solidity
uint256 internal constant NOT_IN_RECOVERY_MODE = 438;
```


### INDUCED_FAILURE

```solidity
uint256 internal constant INDUCED_FAILURE = 439;
```


### EXPIRED_SIGNATURE

```solidity
uint256 internal constant EXPIRED_SIGNATURE = 440;
```


### MALFORMED_SIGNATURE

```solidity
uint256 internal constant MALFORMED_SIGNATURE = 441;
```


### SAFE_CAST_VALUE_CANT_FIT_UINT64

```solidity
uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_UINT64 = 442;
```


### UNHANDLED_FEE_TYPE

```solidity
uint256 internal constant UNHANDLED_FEE_TYPE = 443;
```


### BURN_FROM_ZERO

```solidity
uint256 internal constant BURN_FROM_ZERO = 444;
```


### INVALID_POOL_ID

```solidity
uint256 internal constant INVALID_POOL_ID = 500;
```


### CALLER_NOT_POOL

```solidity
uint256 internal constant CALLER_NOT_POOL = 501;
```


### SENDER_NOT_ASSET_MANAGER

```solidity
uint256 internal constant SENDER_NOT_ASSET_MANAGER = 502;
```


### USER_DOESNT_ALLOW_RELAYER

```solidity
uint256 internal constant USER_DOESNT_ALLOW_RELAYER = 503;
```


### INVALID_SIGNATURE

```solidity
uint256 internal constant INVALID_SIGNATURE = 504;
```


### EXIT_BELOW_MIN

```solidity
uint256 internal constant EXIT_BELOW_MIN = 505;
```


### JOIN_ABOVE_MAX

```solidity
uint256 internal constant JOIN_ABOVE_MAX = 506;
```


### SWAP_LIMIT

```solidity
uint256 internal constant SWAP_LIMIT = 507;
```


### SWAP_DEADLINE

```solidity
uint256 internal constant SWAP_DEADLINE = 508;
```


### CANNOT_SWAP_SAME_TOKEN

```solidity
uint256 internal constant CANNOT_SWAP_SAME_TOKEN = 509;
```


### UNKNOWN_AMOUNT_IN_FIRST_SWAP

```solidity
uint256 internal constant UNKNOWN_AMOUNT_IN_FIRST_SWAP = 510;
```


### MALCONSTRUCTED_MULTIHOP_SWAP

```solidity
uint256 internal constant MALCONSTRUCTED_MULTIHOP_SWAP = 511;
```


### INTERNAL_BALANCE_OVERFLOW

```solidity
uint256 internal constant INTERNAL_BALANCE_OVERFLOW = 512;
```


### INSUFFICIENT_INTERNAL_BALANCE

```solidity
uint256 internal constant INSUFFICIENT_INTERNAL_BALANCE = 513;
```


### INVALID_ETH_INTERNAL_BALANCE

```solidity
uint256 internal constant INVALID_ETH_INTERNAL_BALANCE = 514;
```


### INVALID_POST_LOAN_BALANCE

```solidity
uint256 internal constant INVALID_POST_LOAN_BALANCE = 515;
```


### INSUFFICIENT_ETH

```solidity
uint256 internal constant INSUFFICIENT_ETH = 516;
```


### UNALLOCATED_ETH

```solidity
uint256 internal constant UNALLOCATED_ETH = 517;
```


### ETH_TRANSFER

```solidity
uint256 internal constant ETH_TRANSFER = 518;
```


### CANNOT_USE_ETH_SENTINEL

```solidity
uint256 internal constant CANNOT_USE_ETH_SENTINEL = 519;
```


### TOKENS_MISMATCH

```solidity
uint256 internal constant TOKENS_MISMATCH = 520;
```


### TOKEN_NOT_REGISTERED

```solidity
uint256 internal constant TOKEN_NOT_REGISTERED = 521;
```


### TOKEN_ALREADY_REGISTERED

```solidity
uint256 internal constant TOKEN_ALREADY_REGISTERED = 522;
```


### TOKENS_ALREADY_SET

```solidity
uint256 internal constant TOKENS_ALREADY_SET = 523;
```


### TOKENS_LENGTH_MUST_BE_2

```solidity
uint256 internal constant TOKENS_LENGTH_MUST_BE_2 = 524;
```


### NONZERO_TOKEN_BALANCE

```solidity
uint256 internal constant NONZERO_TOKEN_BALANCE = 525;
```


### BALANCE_TOTAL_OVERFLOW

```solidity
uint256 internal constant BALANCE_TOTAL_OVERFLOW = 526;
```


### POOL_NO_TOKENS

```solidity
uint256 internal constant POOL_NO_TOKENS = 527;
```


### INSUFFICIENT_FLASH_LOAN_BALANCE

```solidity
uint256 internal constant INSUFFICIENT_FLASH_LOAN_BALANCE = 528;
```


### SWAP_FEE_PERCENTAGE_TOO_HIGH

```solidity
uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 600;
```


### FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH

```solidity
uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 601;
```


### INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT

```solidity
uint256 internal constant INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT = 602;
```


### AUM_FEE_PERCENTAGE_TOO_HIGH

```solidity
uint256 internal constant AUM_FEE_PERCENTAGE_TOO_HIGH = 603;
```


### UNIMPLEMENTED

```solidity
uint256 internal constant UNIMPLEMENTED = 998;
```


### SHOULD_NOT_HAPPEN

```solidity
uint256 internal constant SHOULD_NOT_HAPPEN = 999;
```


