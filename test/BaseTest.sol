// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "lib/forge-std/src/console2.sol";
import { DSTest } from "ds-test/test.sol";
import { DSTestPlus } from "./utils/DSTestPlus.sol";
import { VotingEscrow } from "src/VotingEscrow.sol";
import { AlchemixGovernor } from "src/AlchemixGovernor.sol";
import { ManaToken } from "src/ManaToken.sol";
import { Voter } from "src/Voter.sol";
import { GaugeFactory } from "src/factories/GaugeFactory.sol";
import { BribeFactory } from "src/factories/BribeFactory.sol";
import { Minter, InitializationParams } from "src/Minter.sol";
import { IAlchemixToken } from "src/interfaces/IAlchemixToken.sol";
import "src/governance/TimelockExecutor.sol";
import "src/StakingGauge.sol";
import "src/RewardsDistributor.sol";
import "src/Bribe.sol";

import "balancer-core-v2/contracts/WeightedPoolFactory.sol";

abstract contract BaseTest is DSTestPlus {
    IAlchemixToken public alcx = IAlchemixToken(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
    IERC20 public bpt = IERC20(0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56);
    IERC20 public veBAL = IERC20(0xC128a9954e6c874eA3d62ce62B468bA073093F25);
    IERC20 public galcx = IERC20(0x93Dede06AE3B5590aF1d4c111BC54C3f717E4b35);
    WeightedPoolFactory balancerPoolFactory = WeightedPoolFactory(0xA5bf2ddF098bb0Ef6d120C98217dD6B141c74EE0);
    address constant admin = 0x8392F6669292fA56123F71949B52d883aE57e225;
    address account = address(0xbeef);
    address public alETHPool = 0xC4C319E2D4d66CcA4464C0c2B32c9Bd23ebe784e;
    address public alUSDPool = 0x9735F7d3Ea56b454b24fFD74C58E9bD85cfaD31B;
    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    ManaToken public MANA = new ManaToken(admin);
    VotingEscrow veALCX = new VotingEscrow(address(bpt), address(alcx), address(MANA));

    uint256 internal constant MAXTIME = 365 days;
    uint256 internal constant MULTIPLIER = 26 ether;

    uint256 public mainnet = 1;

    // Values for the current epoch (emissions to be manually minted)
    uint256 public supply = 1793678e18;
    uint256 public rewards = 12724e18;
    uint256 public stepdown = 130e18;
    uint256 public supplyAtTail = 2392609e18;

    uint256 constant TOKEN_1 = 1e18;
    uint256 constant TOKEN_100K = 1e23; // 1e5 = 100K tokens with 18 decimals
    uint256 constant TOKEN_1M = 1e24; // 1e6 = 1M tokens with 18 decimals
    uint256 constant TOKEN_100M = 1e26; // 1e8 = 100M tokens with 18 decimals
    uint256 constant TOKEN_10B = 1e28; // 1e10 = 10B tokens with 18 decimals

    function mintAlcx(address _account, uint256 _amount) public {
        hevm.startPrank(admin);

        alcx.grantRole(keccak256("MINTER"), admin);
        alcx.mint(_account, _amount);

        hevm.stopPrank();
    }

    function mintMana(address _account, uint256 _amount) public {
        hevm.startPrank(admin);

        MANA.mint(_account, _amount);

        hevm.stopPrank();
    }

    function mintBpt(address _account, uint256 _amount) public {
        hevm.startPrank(address(veBAL));

        bpt.approve(address(veBAL), _amount);
        bpt.transfer(_account, _amount);

        hevm.stopPrank();
    }

    function createBalancerPool() public {
        hevm.startPrank(admin);

        address bptPool = balancerPoolFactory.create(
            "Balancer 80 ALCX 20 WETH",
            "B-80ALCX-20WETH",
            [address(alcx), address(weth)],
            [800000000000000000, 200000000000000000],
            3000000000000000,
            true,
            address(0xBA1BA1ba1BA1bA1bA1Ba1BA1ba1BA1bA1ba1ba1B)
        );

        bytes32 poolId = bptPool.getPoolId();
        console2.log("poolId", poolId);

        hevm.stopPrank();
    }

    function approveAmount(
        address _account,
        address _spender,
        uint256 _amount
    ) public {
        hevm.startPrank(_account);

        alcx.approve(_spender, _amount);

        hevm.stopPrank();
    }

    function setMinter(address _minter) public {
        hevm.startPrank(admin);

        alcx.grantRole(keccak256("MINTER"), address(_minter));

        hevm.stopPrank();
    }

    // Returns the max voting power given a deposit amount and length
    function getMaxVotingPower(uint256 _amount, uint256 _end) public view returns (uint256) {
        uint256 slope = (_amount * MULTIPLIER) / MAXTIME;

        uint256 bias = (slope * (_end - block.timestamp)) + _amount;

        return bias;
    }
}
