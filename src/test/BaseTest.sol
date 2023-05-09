// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "lib/forge-std/src/console2.sol";
import "lib/forge-std/src/Test.sol";
import "./utils/DSTestPlus.sol";

import "src/VotingEscrow.sol";
import "src/AlchemixGovernor.sol";
import "src/FluxToken.sol";
import "src/Voter.sol";
import "src/Minter.sol";
import "src/RewardsDistributor.sol";
import "src/RevenueHandler.sol";
import "src/Bribe.sol";
import "src/gauges/CurveGauge.sol";
import "src/gauges/PassthroughGauge.sol";
import "src/governance/TimelockExecutor.sol";
import "src/factories/BribeFactory.sol";
import "src/factories/GaugeFactory.sol";

import "src/interfaces/aura/MockCurveGaugeFactory.sol";
import "src/interfaces/IAlchemixToken.sol";
import "src/interfaces/IMinter.sol";
import "src/interfaces/balancer/WeightedPool2TokensFactory.sol";
import "src/interfaces/balancer/WeightedPoolUserData.sol";
import "src/interfaces/balancer/IVault.sol";
import "src/interfaces/IWETH9.sol";
import "src/gauges/StakingRewards.sol";
import "src/interfaces/aura/IRewardPool4626.sol";

contract BaseTest is DSTestPlus {
    address public admin = 0x8392F6669292fA56123F71949B52d883aE57e225;
    address public devmsig = 0x9e2b6378ee8ad2A4A95Fe481d63CAba8FB0EBBF9;
    address public time = 0x869d1b8610c038A6C4F37bD757135d4C29ae8917;
    address public alETHPool = 0xC4C319E2D4d66CcA4464C0c2B32c9Bd23ebe784e;
    address public alUSDPool = 0x9735F7d3Ea56b454b24fFD74C58E9bD85cfaD31B;
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public alusd = 0xBC6DA0FE9aD5f3b0d58160288917AA56653660E9;
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    address public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public bal = 0xba100000625a3754423978a60c9317c58a424e3D;
    address public aura = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
    address public aleth = 0x0100546F2cD4C9D97f798fFC9755E47865FF7Ee6;
    address public alusd3crv = 0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c;
    address public alethcrv = 0xC4C319E2D4d66CcA4464C0c2B32c9Bd23ebe784e;
    address public priceFeed = 0x194a9AaF2e0b67c35915cD01101585A33Fe25CAa;
    address public holder = 0x000000000000000000000000000000000000dEaD;
    address public beef = address(0xbeef);
    address public dead = address(0xdead);
    address public bpt = 0xf16aEe6a71aF1A9Bc8F56975A4c2705ca7A782Bc;
    address public rewardPool = 0x8B227E3D50117E80a02cd0c67Cd6F89A8b7B46d7;

    // Pool addresses
    address public alUsdPoolAddress = 0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c;
    address public alEthPoolAddress = 0xC4C319E2D4d66CcA4464C0c2B32c9Bd23ebe784e;
    address public alUsdFraxBpPoolAddress = 0xB30dA2376F63De30b42dC055C93fa474F31330A5;
    address public sushiPoolAddress = 0x7519C93fC5073E15d89131fD38118D73A72370F8;

    // Votium pool indexes
    // These are subject to change
    uint256 public alUsdIndex = 34;
    uint256 public alEthIndex = 46;
    uint256 public alUsdFraxBpIndex = 105;

    // Votium contract that is sent rewards
    address public votiumReceiver = 0x19BBC3463Dd8d07f55438014b021Fb457EBD4595;

    // Votium contract that receives rewards (via the receiver)
    address public votiumStash = 0x378Ba9B73309bE80BF4C2c027aAD799766a7ED5A;

    // Proposal id from snapshot url
    // https://snapshot.org/#/cvx.eth/proposal/0xd2f6785ba7e199e3a0169c9bfd561ae6d7c81baa54de4291eef0c355251eb94c
    bytes32 public proposal = 0xd2f6785ba7e199e3a0169c9bfd561ae6d7c81baa54de4291eef0c355251eb94c;

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
    uint256 internal constant BPS = 10_000;

    WeightedPool2TokensFactory poolFactory = WeightedPool2TokensFactory(0xA5bf2ddF098bb0Ef6d120C98217dD6B141c74EE0);
    IAlchemixToken public alcx = IAlchemixToken(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
    IERC20 public galcx = IERC20(0x93Dede06AE3B5590aF1d4c111BC54C3f717E4b35);
    IERC20 public weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IVault public balancerVault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    FluxToken public flux = new FluxToken(admin);

    MockCurveGaugeFactory public mockCurveGaugeFactory = new MockCurveGaugeFactory();

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
    StakingRewards public timeGauge;

    // Initialize all DAO contracts and their dependencies
    function setupContracts(uint256 _time) public {
        deal(bpt, admin, TOKEN_100M);
        deal(address(weth), admin, TOKEN_100M);

        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = bal;

        // Setup contracts at specific point in time
        hevm.warp(_time);

        veALCX = new VotingEscrow(bpt, address(alcx), address(flux), address(rewardPool), admin);

        veALCX.setVoter(admin);
        veALCX.setRewardsDistributor(admin);
        veALCX.addRewardPoolToken(bal);
        veALCX.addRewardPoolToken(aura);

        hevm.startPrank(admin);

        IERC20(bpt).approve(address(veALCX), type(uint256).max);

        FluxToken(flux).setMinter(address(veALCX));

        timeGauge = new StakingRewards(address(this), address(alcx), time);
        revenueHandler = new RevenueHandler(address(veALCX), admin, 0);
        gaugeFactory = new GaugeFactory();
        bribeFactory = new BribeFactory();
        voter = new Voter(address(veALCX), address(gaugeFactory), address(bribeFactory), address(flux));
        distributor = new RewardsDistributor(address(veALCX), address(weth), address(balancerVault), priceFeed);
        address[] memory schedulerCancellerArray = new address[](1);
        schedulerCancellerArray[0] = admin;
        address[] memory executorArray = new address[](1);
        executorArray[0] = address(0);
        timelockExecutor = new TimelockExecutor(
            1 days,
            schedulerCancellerArray,
            schedulerCancellerArray,
            executorArray
        );
        governor = new AlchemixGovernor(veALCX, TimelockExecutor(timelockExecutor));

        timelockExecutor.grantRole(timelockExecutor.SCHEDULER_ROLE(), address(governor));
        timelockExecutor.grantRole(timelockExecutor.TIMELOCK_ADMIN_ROLE(), address(governor));
        voter.setAdmin(address(timelockExecutor));

        veALCX.setVoter(address(voter));
        veALCX.setRewardsDistributor(address(distributor));

        IMinter.InitializationParams memory params = IMinter.InitializationParams(
            address(alcx),
            address(voter),
            address(veALCX),
            address(distributor),
            address(revenueHandler),
            address(timeGauge),
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

        // Get address of new gauges
        address alUsdGaugeAddress = voter.gauges(alUsdPoolAddress);
        address alEthGaugeAddress = voter.gauges(alEthPoolAddress);
        address alUsdFraxBpGaugeAddress = voter.gauges(alUsdFraxBpPoolAddress);
        address sushiGaugeAddress = voter.gauges(sushiPoolAddress);

        alUsdGauge = CurveGauge(alUsdGaugeAddress);
        alEthGauge = CurveGauge(alEthGaugeAddress);
        alUsdFraxBpGauge = CurveGauge(alUsdFraxBpGaugeAddress);
        sushiGauge = PassthroughGauge(sushiGaugeAddress);

        alUsdGauge.initialize(alUsdIndex, votiumReceiver);
        alEthGauge.initialize(alEthIndex, votiumReceiver);
        alUsdFraxBpGauge.initialize(alUsdFraxBpIndex, votiumReceiver);

        hevm.stopPrank();
        timeGauge.setRewardsDistribution(address(minter));

        hevm.prank(address(timelockExecutor));
        voter.acceptAdmin();
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

        uint256 bias = (slope * (_end - block.timestamp));

        return bias;
    }

    function createThirdPartyBribe(address _bribeAddress, address _token, uint256 _amount) public {
        deal(_token, address(this), _amount);

        IERC20(_token).approve(_bribeAddress, _amount);

        hevm.prank(address(timelockExecutor));
        IVoter(voter).whitelist(_token);

        IBribe(_bribeAddress).notifyRewardAmount(_token, _amount);
    }
}
