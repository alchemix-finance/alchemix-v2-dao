// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {DSTest} from "ds-test/test.sol";

import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {Hevm} from "./utils/Hevm.sol";

interface Vm {
    function prank(address) external;
}

interface StakingPools {
    function acceptGovernance() external;
    function claim(uint256 _poolId) external;
    function createPool(address _token) external returns (uint256);
    function deposit(uint256 _poolId, uint256 _depositAmount) external;
    function exit(uint256 _poolId) external;
    function getPoolRewardRate(uint256 _poolId) view external returns (uint256);
    function getPoolRewardWeight(uint256 _poolId) view external returns (uint256);
    function getPoolToken(uint256 _poolId) view external returns (address);
    function getPoolTotalDeposited(uint256 _poolId) view external returns (uint256);
    function getStakeTotalDeposited(address _account, uint256 _poolId) view external returns (uint256);
    function getStakeTotalUnclaimed(address _account, uint256 _poolId) view external returns (uint256);
    function governance() view external returns (address);
    function pendingGovernance() view external returns (address);
    function poolCount() view external returns (uint256);
    function reward() view external returns (address);
    function rewardRate() view external returns (uint256);
    function setPendingGovernance(address _pendingGovernance) external;
    function setRewardRate(uint256 _rewardRate) external;
    function setRewardWeights(uint256[] memory _rewardWeights) external;
    function tokenPoolIds(address) view external returns (uint256);
    function totalRewardWeight() view external returns (uint256);
    function withdraw(uint256 _poolId, uint256 _withdrawAmount) external;
}

contract ContractTest is DSTestPlus {
    // Hevm internal constant hevm = Hevm(HEVM_ADDRESS);
    StakingPools internal constant pool = StakingPools(0xAB8e74017a8Cc7c15FFcCd726603790d26d7DeCa);
    address internal constant user = 0x7DcE9D1cFB18a0Db23E7e3037F1e56A3070517E2;

    function setUp() public {
        // ALCX single-sided is pool id 1
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
}
