// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "lib/forge-std/src/console2.sol";
import "lib/forge-std/src/Test.sol";
import "./utils/DSTestPlus.sol";

import "src/VotingEscrow.sol";
import "src/AlchemixGovernor.sol";
import "src/ManaToken.sol";
import "src/Voter.sol";
import "src/Minter.sol";
import "src/RewardsDistributor.sol";
import "src/RevenueHandler.sol";
import "src/Bribe.sol";
import "src/gauges/CurveGauge.sol";
import "src/gauges/PassthroughGauge.sol";
import "src/gauges/StakingGauge.sol";
import "src/governance/TimelockExecutor.sol";
import "src/factories/BribeFactory.sol";
import "src/factories/GaugeFactory.sol";

import "src/interfaces/IAlchemixToken.sol";
import "src/interfaces/IMinter.sol";
import "src/interfaces/balancer/WeightedPool2TokensFactory.sol";
import "src/interfaces/balancer/WeightedPoolUserData.sol";
import "src/interfaces/balancer/IVault.sol";
import "src/interfaces/balancer/IBasePool.sol";
import "src/interfaces/balancer/IAsset.sol";
import "src/interfaces/IWETH9.sol";

contract BaseTest is DSTestPlus {
    address public admin = 0x8392F6669292fA56123F71949B52d883aE57e225;
    address public devmsig = 0x9e2b6378ee8ad2A4A95Fe481d63CAba8FB0EBBF9;
    address public alETHPool = 0xC4C319E2D4d66CcA4464C0c2B32c9Bd23ebe784e;
    address public alUSDPool = 0x9735F7d3Ea56b454b24fFD74C58E9bD85cfaD31B;
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public alusd = 0xBC6DA0FE9aD5f3b0d58160288917AA56653660E9;
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    address public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public bal = 0xba100000625a3754423978a60c9317c58a424e3D;
    address public aleth = 0x0100546F2cD4C9D97f798fFC9755E47865FF7Ee6;
    address public alusd3crv = 0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c;
    address public alethcrv = 0xC4C319E2D4d66CcA4464C0c2B32c9Bd23ebe784e;
    address public priceFeed = 0x194a9AaF2e0b67c35915cD01101585A33Fe25CAa;
    address public holder = 0x000000000000000000000000000000000000dEaD;
    address public beef = address(0xbeef);
    address public dead = address(0xdead);
    address public bpt;

    // Pool addresses
    address public alUsdPoolAddress = 0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c;
    address public alEthPoolAddress = 0xC4C319E2D4d66CcA4464C0c2B32c9Bd23ebe784e;
    address public alUsdFraxBpPoolAddress = 0xB30dA2376F63De30b42dC055C93fa474F31330A5;
    address public sushiPoolAddress = 0x7519C93fC5073E15d89131fD38118D73A72370F8;

    // Votium pool indexes
    uint256 public alUsdIndex = 34;
    uint256 public alEthIndex = 46;
    uint256 public alUsdFraxBpIndex = 105;

    // Votium contract that is sent rewards
    address public votiumReceiver = 0x19BBC3463Dd8d07f55438014b021Fb457EBD4595;

    // Votium contract that receives rewards (via the receiver)
    address public votiumStash = 0x378Ba9B73309bE80BF4C2c027aAD799766a7ED5A;

    // Proposal id from snapshot url
    // https://snapshot.org/#/cvx.eth/proposal/0xd7db40d1ca142cb5ca24bce5d0f78f3b037fde6c7ebb3c3650a317e910278b1f
    bytes32 public proposal = 0xd7db40d1ca142cb5ca24bce5d0f78f3b037fde6c7ebb3c3650a317e910278b1f;

    // Values for the current epoch (emissions to be manually minted)
    uint256 public supply = 1793678e18;
    uint256 public rewards = 12724e18;
    uint256 public stepdown = 130e18;
    uint256 public supplyAtTail = 2392609e18;
    uint256 public nextEpoch = 2 weeks;

    uint256 constant MAINNET = 1;
    uint256 constant TOKEN_1 = 1e18;
    uint256 constant TOKEN_100K = 1e23; // 1e5 = 100K tokens with 18 decimals
    uint256 constant TOKEN_1M = 1e24; // 1e6 = 1M tokens with 18 decimals
    uint256 constant TOKEN_100M = 1e26; // 1e8 = 100M tokens with 18 decimals
    uint256 constant TOKEN_10B = 1e28; // 1e10 = 10B tokens with 18 decimals

    uint256 internal constant MAXTIME = 365 days;
    uint256 internal constant MULTIPLIER = 26 ether;

    WeightedPool2TokensFactory poolFactory = WeightedPool2TokensFactory(0xA5bf2ddF098bb0Ef6d120C98217dD6B141c74EE0);
    IAlchemixToken public alcx = IAlchemixToken(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
    IERC20 public galcx = IERC20(0x93Dede06AE3B5590aF1d4c111BC54C3f717E4b35);
    IERC20 public weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IVault public balancerVault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    ManaToken public mana = new ManaToken(admin);

    VotingEscrow public veALCX;
    Voter public voter;
    GaugeFactory public gaugeFactory;
    BribeFactory public bribeFactory;
    RewardsDistributor public distributor;
    Minter public minter;
    RevenueHandler public revenueHandler;
    TimelockExecutor public timelockExecutor;
    AlchemixGovernor public governor;
    CurveGauge public alUsdGauge;
    CurveGauge public alEthGauge;
    CurveGauge public alUsdFraxBpGauge;
    PassthroughGauge public sushiGauge;
    StakingGauge public stakingGauge;
    StakingGauge public stakingGauge2;

    // Initialize all DAO contracts and their dependencies
    function setupContracts(uint256 _time) public {
        bpt = createBalancerPool();

        // Run contracts at specific point in time
        hevm.warp(_time);

        veALCX = new VotingEscrow(bpt, address(alcx), address(mana));

        veALCX.setVoter(admin);
        veALCX.setRewardsDistributor(admin);

        hevm.startPrank(admin);

        IERC20(bpt).approve(address(veALCX), type(uint256).max);

        ManaToken(mana).setMinter(address(veALCX));

        revenueHandler = new RevenueHandler(address(veALCX));
        gaugeFactory = new GaugeFactory();
        bribeFactory = new BribeFactory();
        voter = new Voter(address(veALCX), address(gaugeFactory), address(bribeFactory), address(mana));
        distributor = new RewardsDistributor(address(veALCX), address(weth), address(balancerVault), priceFeed);
        timelockExecutor = new TimelockExecutor(1 days);
        governor = new AlchemixGovernor(veALCX, TimelockExecutor(timelockExecutor));

        timelockExecutor.setAdmin(address(governor));
        voter.setAdmin(address(timelockExecutor));

        veALCX.setVoter(address(voter));
        veALCX.setRewardsDistributor(address(distributor));

        IMinter.InitializationParams memory params = IMinter.InitializationParams(
            address(alcx),
            address(voter),
            address(veALCX),
            address(distributor),
            address(revenueHandler),
            supply,
            rewards,
            stepdown
        );

        minter = new Minter(params);

        distributor.setDepositor(address(minter));
        voter.initialize(address(alcx), address(minter));
        alcx.grantRole(keccak256("MINTER"), address(minter));

        minter.initialize();

        // Create curve gauges
        voter.createGauge(alUsdPoolAddress, IVoter.GaugeType.Curve);
        voter.createGauge(alEthPoolAddress, IVoter.GaugeType.Curve);
        voter.createGauge(alUsdFraxBpPoolAddress, IVoter.GaugeType.Curve);

        // Create sushi gauge
        voter.createGauge(sushiPoolAddress, IVoter.GaugeType.Passthrough);

        // Create staking gauges
        voter.createGauge(address(alcx), IVoter.GaugeType.Staking);
        voter.createGauge(alUSDPool, IVoter.GaugeType.Staking);

        // Get address of new gauges
        address alUsdGaugeAddress = voter.gauges(alUsdPoolAddress);
        address alEthGaugeAddress = voter.gauges(alEthPoolAddress);
        address alUsdFraxBpGaugeAddress = voter.gauges(alUsdFraxBpPoolAddress);
        address sushiGaugeAddress = voter.gauges(sushiPoolAddress);
        address gaugeAddress = voter.gauges(address(alcx));
        address gaugeAddress2 = voter.gauges(alUSDPool);

        alUsdGauge = CurveGauge(alUsdGaugeAddress);
        alEthGauge = CurveGauge(alEthGaugeAddress);
        alUsdFraxBpGauge = CurveGauge(alUsdFraxBpGaugeAddress);
        sushiGauge = PassthroughGauge(sushiGaugeAddress);
        stakingGauge = StakingGauge(gaugeAddress);
        stakingGauge2 = StakingGauge(gaugeAddress2);

        alUsdGauge.initialize(alUsdIndex, votiumReceiver);
        alEthGauge.initialize(alEthIndex, votiumReceiver);
        alUsdFraxBpGauge.initialize(alUsdFraxBpIndex, votiumReceiver);

        hevm.stopPrank();

        hevm.prank(address(governor));
        timelockExecutor.acceptAdmin();

        hevm.prank(address(timelockExecutor));
        voter.acceptAdmin();
    }

    // Initializes 80 ALCX 20 WETH Balancer pool and makes an initial deposit
    function createBalancerPool() public returns (address) {
        deal(address(alcx), admin, TOKEN_100M);
        deal(address(weth), admin, TOKEN_100M);

        hevm.startPrank(admin);

        string memory name = "Balancer 80 ALCX 20 WETH";
        string memory symbol = "B-80ALCX-20WETH";
        address[] memory tokens = new address[](2);
        tokens[0] = address(weth);
        tokens[1] = address(alcx);
        uint256[] memory weights = new uint256[](2);
        weights[0] = uint256(200000000000000000);
        weights[1] = uint256(800000000000000000);
        uint256 swapFeePercentage = 3000000000000000;
        bool oracleEnabled = true;
        address owner = 0x0000000000000000000000000000000000000000;

        address balancerPool = poolFactory.create(
            name,
            symbol,
            tokens,
            weights,
            swapFeePercentage,
            oracleEnabled,
            owner
        );

        bytes32 poolId = IBasePool(balancerPool).getPoolId();

        alcx.approve(address(balancerVault), TOKEN_1M * 2);
        weth.approve(address(balancerVault), TOKEN_1M);

        IAsset[] memory _assets = new IAsset[](2);
        _assets[0] = IAsset(address(weth));
        _assets[1] = IAsset(address(alcx));

        uint256[] memory amountsIn = new uint256[](2);
        amountsIn[0] = TOKEN_1M;
        amountsIn[1] = TOKEN_1M * 2;

        uint256 amountOut = 0;

        bytes memory _userData = abi.encode(WeightedPoolUserData.JoinKind.INIT, amountsIn, amountOut);

        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest({
            assets: _assets,
            maxAmountsIn: amountsIn,
            userData: _userData,
            fromInternalBalance: false
        });

        balancerVault.joinPool(poolId, admin, admin, request);

        hevm.stopPrank();

        return balancerPool;
    }

    // Creates a veALCX position for a given account
    function createVeAlcx(
        address _account,
        uint256 _amount,
        uint256 _time,
        bool _maxLockEnabled
    ) public returns (uint256) {
        deal(bpt, address(this), _amount);

        IERC20(bpt).approve(address(veALCX), _amount);

        uint256 tokenId = veALCX.createLockFor(_amount, _time, _maxLockEnabled, _account);

        uint256 maxVotingPower = getMaxVotingPower(_amount, veALCX.lockEnd(tokenId));

        assertEq(veALCX.balanceOfToken(tokenId), maxVotingPower);

        assertEq(veALCX.ownerOf(tokenId), _account);

        return tokenId;
    }

    // Returns the max voting power given a deposit amount and length
    function getMaxVotingPower(uint256 _amount, uint256 _end) public view returns (uint256) {
        uint256 slope = (_amount * MULTIPLIER) / MAXTIME;

        uint256 bias = (slope * (_end - block.timestamp)) + _amount;

        return bias;
    }

    function createThirdPartyBribe(address _bribeAddress, address _token, uint256 _amount) public {
        deal(_token, address(this), _amount);

        IERC20(_token).approve(_bribeAddress, _amount);

        IBribe(_bribeAddress).notifyRewardAmount(_token, _amount);
    }
}
