# BaseTest
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/test/BaseTest.sol)

**Inherits:**
[DSTestPlus](/src/test/utils/DSTestPlus.sol/contract.DSTestPlus.md)


## State Variables
### admin

```solidity
address public admin = 0x8392F6669292fA56123F71949B52d883aE57e225;
```


### devmsig

```solidity
address public devmsig = 0x9e2b6378ee8ad2A4A95Fe481d63CAba8FB0EBBF9;
```


### time

```solidity
address public time = 0x869d1b8610c038A6C4F37bD757135d4C29ae8917;
```


### alETHPool

```solidity
address public alETHPool = 0xC4C319E2D4d66CcA4464C0c2B32c9Bd23ebe784e;
```


### alUSDPool

```solidity
address public alUSDPool = 0x9735F7d3Ea56b454b24fFD74C58E9bD85cfaD31B;
```


### usdc

```solidity
address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
```


### alusd

```solidity
address public alusd = 0xBC6DA0FE9aD5f3b0d58160288917AA56653660E9;
```


### dai

```solidity
address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
```


### ydai

```solidity
address public ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
```


### usdt

```solidity
address public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
```


### bal

```solidity
address public bal = 0xba100000625a3754423978a60c9317c58a424e3D;
```


### aura

```solidity
address public aura = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
```


### aleth

```solidity
address public aleth = 0x0100546F2cD4C9D97f798fFC9755E47865FF7Ee6;
```


### alusd3crv

```solidity
address public alusd3crv = 0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c;
```


### alethcrv

```solidity
address public alethcrv = 0xC4C319E2D4d66CcA4464C0c2B32c9Bd23ebe784e;
```


### priceFeed

```solidity
address public priceFeed = 0x194a9AaF2e0b67c35915cD01101585A33Fe25CAa;
```


### holder

```solidity
address public holder = 0x000000000000000000000000000000000000dEaD;
```


### beef

```solidity
address public beef = address(0xbeef);
```


### dead

```solidity
address public dead = address(0xdead);
```


### bpt

```solidity
address public bpt = 0xf16aEe6a71aF1A9Bc8F56975A4c2705ca7A782Bc;
```


### rewardPool

```solidity
address public rewardPool = 0x8B227E3D50117E80a02cd0c67Cd6F89A8b7B46d7;
```


### alchemechNFT

```solidity
address public alchemechNFT = 0x672CA2e7136c5b5086178740bA649B6132e607c4;
```


### patronNFT

```solidity
address public patronNFT = 0xA797b1C128b314384fC3517d95BE18fa76Ba5835;
```


### alUsdPoolAddress

```solidity
address public alUsdPoolAddress = 0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c;
```


### alEthPoolAddress

```solidity
address public alEthPoolAddress = 0xC4C319E2D4d66CcA4464C0c2B32c9Bd23ebe784e;
```


### alUsdFraxBpPoolAddress

```solidity
address public alUsdFraxBpPoolAddress = 0xB30dA2376F63De30b42dC055C93fa474F31330A5;
```


### sushiPoolAddress

```solidity
address public sushiPoolAddress = 0x7519C93fC5073E15d89131fD38118D73A72370F8;
```


### balancerPoolAddress

```solidity
address public balancerPoolAddress = 0xf16aEe6a71aF1A9Bc8F56975A4c2705ca7A782Bc;
```


### alUsdIndex

```solidity
uint256 public alUsdIndex = 34;
```


### alEthIndex

```solidity
uint256 public alEthIndex = 46;
```


### alUsdFraxBpIndex

```solidity
uint256 public alUsdFraxBpIndex = 105;
```


### votiumReceiver

```solidity
address public votiumReceiver = 0x19BBC3463Dd8d07f55438014b021Fb457EBD4595;
```


### votiumStash

```solidity
address public votiumStash = 0x378Ba9B73309bE80BF4C2c027aAD799766a7ED5A;
```


### proposal

```solidity
bytes32 public proposal = 0xd2f6785ba7e199e3a0169c9bfd561ae6d7c81baa54de4291eef0c355251eb94c;
```


### supply

```solidity
uint256 public supply = 1793678e18;
```


### rewards

```solidity
uint256 public rewards = 12724e18;
```


### stepdown

```solidity
uint256 public stepdown = 130e18;
```


### supplyAtTail

```solidity
uint256 public supplyAtTail = 2392609e18;
```


### nextEpoch

```solidity
uint256 public nextEpoch = 2 weeks + 1 seconds;
```


### MAINNET

```solidity
uint256 constant MAINNET = 1;
```


### TOKEN_1

```solidity
uint256 constant TOKEN_1 = 1e18;
```


### TOKEN_100K

```solidity
uint256 constant TOKEN_100K = 1e23;
```


### TOKEN_1M

```solidity
uint256 constant TOKEN_1M = 1e24;
```


### TOKEN_100M

```solidity
uint256 constant TOKEN_100M = 1e26;
```


### TOKEN_10B

```solidity
uint256 constant TOKEN_10B = 1e28;
```


### MAXTIME

```solidity
uint256 internal constant MAXTIME = 365 days;
```


### MULTIPLIER

```solidity
uint256 internal constant MULTIPLIER = 2;
```


### BPS

```solidity
uint256 internal constant BPS = 10_000;
```


### poolFactory

```solidity
WeightedPool2TokensFactory poolFactory = WeightedPool2TokensFactory(0xA5bf2ddF098bb0Ef6d120C98217dD6B141c74EE0);
```


### alcx

```solidity
IAlchemixToken public alcx = IAlchemixToken(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
```


### galcx

```solidity
IERC20 public galcx = IERC20(0x93Dede06AE3B5590aF1d4c111BC54C3f717E4b35);
```


### weth

```solidity
IERC20 public weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
```


### balancerVault

```solidity
IVault public balancerVault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
```


### flux

```solidity
FluxToken public flux = new FluxToken(admin);
```


### mockCurveGaugeFactory

```solidity
MockCurveGaugeFactory public mockCurveGaugeFactory = new MockCurveGaugeFactory();
```


### veALCX

```solidity
VotingEscrow public veALCX;
```


### voter

```solidity
Voter public voter;
```


### gaugeFactory

```solidity
GaugeFactory public gaugeFactory;
```


### bribeFactory

```solidity
BribeFactory public bribeFactory;
```


### distributor

```solidity
RewardsDistributor public distributor;
```


### minter

```solidity
Minter public minter;
```


### rewardPoolManager

```solidity
RewardPoolManager public rewardPoolManager;
```


### revenueHandler

```solidity
RevenueHandler public revenueHandler;
```


### timelockExecutor

```solidity
TimelockExecutor public timelockExecutor;
```


### governor

```solidity
AlchemixGovernor public governor;
```


### alUsdGauge

```solidity
CurveGauge public alUsdGauge;
```


### alEthGauge

```solidity
CurveGauge public alEthGauge;
```


### alUsdFraxBpGauge

```solidity
CurveGauge public alUsdFraxBpGauge;
```


### sushiGauge

```solidity
PassthroughGauge public sushiGauge;
```


### balancerGauge

```solidity
PassthroughGauge public balancerGauge;
```


### timeGauge

```solidity
StakingRewards public timeGauge;
```


## Functions
### setupContracts


```solidity
function setupContracts(uint256 _time) public;
```

### createVeAlcx


```solidity
function createVeAlcx(address _account, uint256 _amount, uint256 _time, bool _maxLockEnabled)
    public
    returns (uint256);
```

### getMaxVotingPower


```solidity
function getMaxVotingPower(uint256 _amount, uint256 _end) public view returns (uint256);
```

### createThirdPartyBribe


```solidity
function createThirdPartyBribe(address _bribeAddress, address _token, uint256 _amount) public;
```

