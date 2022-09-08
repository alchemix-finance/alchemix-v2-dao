pragma solidity ^0.8.15;

import "forge-std/console2.sol";
import { DSTest } from "ds-test/test.sol";
import { DSTestPlus } from "./utils/DSTestPlus.sol";
import { VotingEscrow } from "src/VotingEscrow.sol";
import { Voter } from "src/Voter.sol";
import { GaugeFactory } from "src/factories/GaugeFactory.sol";
import { BribeFactory } from "src/factories/BribeFactory.sol";
import { Minter, InitializationParams } from "src/Minter.sol";
import "src/StakingGauge.sol";
import "src/RewardsDistributor.sol";
import { IAlchemixToken } from "src/interfaces/IAlchemixToken.sol";

abstract contract BaseTest is DSTestPlus {
    IAlchemixToken public alcx = IAlchemixToken(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
    address constant admin = 0x8392F6669292fA56123F71949B52d883aE57e225;
    address account = address(0xbeef);
    address public alETHPool = 0xC4C319E2D4d66CcA4464C0c2B32c9Bd23ebe784e;
    address public alUSDPool = 0x9735F7d3Ea56b454b24fFD74C58E9bD85cfaD31B;

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

        alcx.grantRole(keccak256("MINTER"), address(admin));
        alcx.mint(_account, _amount);

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
}
