pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract AlchemixGovernorTest is BaseTest {
    VotingEscrow veALCX;
    Voter voter;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    RewardsDistributor distributor;
    Minter minter;
    StakingGauge gauge;
    Bribe bribe;
    TimelockExecutor timelockExecutor;
    AlchemixGovernor governor;

    function setUp() public {
        mintAlcx(address(admin), 2e25);
        mintAlcx(address(0xbeef), 1e25);

        hevm.startPrank(admin);

        veALCX = new VotingEscrow(address(alcx));
        alcx.approve(address(veALCX), 97 * TOKEN_1);
        veALCX.createLock(97 * TOKEN_1, 4 * 365 * 86400);
        hevm.roll(block.number + 1);

        hevm.stopPrank();

        hevm.startPrank(address(0xbeef));
        alcx.approve(address(veALCX), 3 * TOKEN_1);
        veALCX.createLock(3 * TOKEN_1, 4 * 365 * 86400);
        hevm.roll(block.number + 1);

        hevm.stopPrank();

        hevm.startPrank(admin);

        gaugeFactory = new GaugeFactory();
        bribeFactory = new BribeFactory();
        voter = new Voter(address(veALCX), address(gaugeFactory), address(bribeFactory));

        veALCX.setVoter(address(voter));

        distributor = new RewardsDistributor(address(veALCX));

        InitializationParams memory params = InitializationParams(
            address(voter),
            address(veALCX),
            address(distributor),
            supply,
            rewards,
            stepdown
        );

        minter = new Minter(params);

        distributor.setDepositor(address(minter));

        alcx.grantRole(keccak256("MINTER"), address(minter));

        alcx.approve(address(gaugeFactory), 15 * TOKEN_100K);
        voter.createGauge(address(alETHPool), Voter.GaugeType.Staking);
        address gaugeAddress = voter.gauges(address(alETHPool));
        address bribeAddress = voter.bribes(gaugeAddress);

        timelockExecutor = new TimelockExecutor(1 days);

        governor = new AlchemixGovernor(veALCX, TimelockExecutor(timelockExecutor));
        voter.setGovernor(address(governor));

        hevm.stopPrank();
    }

    function testGovernorCanCreateGaugesForAnyAddress() public {}
}
