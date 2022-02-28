// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {DSTest} from "ds-test/test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {gALCX} from "../gALCX.sol";
import {StakingPools} from "../interfaces/StakingPools.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {Hevm} from "./utils/Hevm.sol";

interface Vm {
    function prank(address) external;
}

contract gALCXTest is DSTestPlus {
    // Hevm internal constant hevm = Hevm(HEVM_ADDRESS);
    IERC20 public alcx = IERC20(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
    StakingPools internal constant pool = StakingPools(0xAB8e74017a8Cc7c15FFcCd726603790d26d7DeCa);
    address internal constant user = 0x7DcE9D1cFB18a0Db23E7e3037F1e56A3070517E2;
    address holder = 0x000000000000000000000000000000000000dEaD;
    gALCX govALCX;


    function setUp() public {
        // ALCX single-sided is pool id 1
        govALCX = new gALCX("governance ALCX", "gALCX");
    }

    function testDeposit() public {
        hevm.startPrank(holder);
        uint gAmount = 999 ether;
        bool success = alcx.approve(address(govALCX), gAmount);
        assertTrue(success);
        govALCX.stake(gAmount);
        uint gBalance = govALCX.balanceOf(holder);
        assertEq(gBalance, gAmount);
    }

    function testRead() public {
        uint rewardRate = pool.rewardRate();
        assertEq(rewardRate, 357911209175627000);
        // emit log_uint(rewardRate);
        // emit log_address(HEVM_ADDRESS);
        // assertTrue(true);
    }

    function testWithdraw() public {
        uint deposited = pool.getStakeTotalDeposited(user, 1);
        // emit log_uint(deposited);
        hevm.prank(user);
        pool.withdraw(1, deposited);
    }

    function testWithdraw(uint256 amount) public {
        uint deposited = pool.getStakeTotalDeposited(user, 1);
        amount = bound(amount, 0, deposited);
        hevm.startPrank(user);
        pool.withdraw(1, amount);
    }

    function testFailWithdrawExtra() public {
        // hevm.expectRevert(
        //     bytes("SafeMath: subtraction overflow")
        // );
        uint deposited = pool.getStakeTotalDeposited(user, 1);
        assertGt(deposited, 0);
        hevm.prank(user);
        pool.withdraw(1, deposited+1);
    }

    function testFailWithdrawExtra(uint256 amount) public {
        uint deposited = pool.getStakeTotalDeposited(user, 1);
        assertGt(deposited, 0);
        amount = bound(amount, deposited+1, amount);
        hevm.prank(user);
        pool.withdraw(1, amount);
    }

    function testMigrateStakingPools() public {
        address owner = govALCX.owner();
        assertEq(owner, address(this));
        // Migrate to the same address (no-op)
        govALCX.migrateStakingPools(address(govALCX.pools()), govALCX.poolId());
    }

}
