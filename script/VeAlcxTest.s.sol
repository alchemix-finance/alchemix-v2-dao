// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "lib/forge-std/src/Script.sol";
import "src/AlcxBpt.sol";
import "src/Alcx.sol";
import "src/FluxToken.sol";
import "src/VotingEscrow.sol";
import "src/Voter.sol";
import "src/Minter.sol";
import "src/RewardPoolManager.sol";
import "src/RewardsDistributor.sol";
import "src/RevenueHandler.sol";
import "src/factories/BribeFactory.sol";
import "src/factories/GaugeFactory.sol";

contract VeAlcxScript is Script {
    uint256 constant TOKEN_1 = 1e18;
    uint256 constant TOKEN_100K = 1e23; // 1e5 = 100K tokens with 18 decimals
    uint256 constant TOKEN_1M = 1e24; // 1e6 = 1M tokens with 18 decimals

    // Values for emissions starting point
    uint256 public supply = 1793678e18;
    uint256 public rewards = 12724e18;
    uint256 public stepdown = 130e18;

    VotingEscrow public veALCX;
    Voter public voter;
    RewardPoolManager public rewardPoolManager;
    RewardsDistributor public distributor;
    Minter public minter;
    RevenueHandler public revenueHandler;
    GaugeFactory public gaugeFactory;
    BribeFactory public bribeFactory;

    // contracts not used in lite deployment
    address public timelockExecutor;
    address public governor;
    address public timeGauge;

    function run() external {
        address dead = address(0xdead);

        uint256 deployerPK = vm.envUint("PRIVATE_KEY");

        address deployer = vm.addr(deployerPK);

        address admin = deployer;

        vm.startBroadcast(deployer);

        // Test tokens for deployment
        AlcxBpt alcxBpt = new AlcxBpt(deployer);
        Alcx alcx = new Alcx(deployer);
        FluxToken flux = new FluxToken(deployer);

        veALCX = new VotingEscrow(address(alcxBpt), address(alcx), address(flux), admin);

        rewardPoolManager = new RewardPoolManager(admin, address(veALCX), address(alcxBpt), dead, admin);

        veALCX.setVoter(admin);
        veALCX.setRewardsDistributor(admin);
        veALCX.setRewardPoolManager(dead);

        FluxToken(flux).mint(deployer, TOKEN_1M);

        timeGauge = admin;
        revenueHandler = new RevenueHandler(address(veALCX), admin, 0);
        gaugeFactory = new GaugeFactory();
        bribeFactory = new BribeFactory();
        voter = new Voter(address(veALCX), address(gaugeFactory), address(bribeFactory), address(flux), address(alcx));

        distributor = new RewardsDistributor(address(veALCX), dead, dead, dead);

        veALCX.setVoter(address(voter));
        veALCX.setRewardsDistributor(address(distributor));

        flux.setMinter(address(veALCX));
        flux.setVeALCX(address(veALCX));
        flux.setVoter(address(voter));

        // timelockExecutor = dead;
        // governor = dead;

        // veALCX.setVoter(address(voter));
        veALCX.setRewardsDistributor(address(distributor));

        IMinter.InitializationParams memory params = IMinter.InitializationParams(
            address(alcx),
            address(voter),
            address(veALCX),
            address(distributor),
            address(revenueHandler),
            address(timeGauge),
            admin,
            supply,
            rewards,
            stepdown
        );

        minter = new Minter(params);

        distributor.setDepositor(address(minter));
        voter.setMinter(address(minter));

        Alcx(alcx).mint(deployer, TOKEN_1M);
        Alcx(alcx).setMinter(address(minter));

        minter.initialize();

        voter.createGauge(admin, IVoter.GaugeType.Passthrough);

        vm.stopBroadcast();
    }
}
