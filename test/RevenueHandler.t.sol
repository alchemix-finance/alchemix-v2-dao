// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./BaseTest.sol";
import "../src/RevenueHandler.sol";
import "../src/CurvePoolAdapter.sol";
import "./utils/DSTestPlus.sol";

contract RevenueHandlerTest is BaseTest {
    address holder = 0x000000000000000000000000000000000000dEaD;
    address alusd = 0xBC6DA0FE9aD5f3b0d58160288917AA56653660E9;
    address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address alusd3crv = 0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c;

    RevenueHandler rh;
    CurvePoolAdapter cpa;

    /// @dev Deploy the contract
    function setUp() public {
        address[] memory alusd3crvTokenIds = new address[](4);
        alusd3crvTokenIds[0] = 0xBC6DA0FE9aD5f3b0d58160288917AA56653660E9;
        alusd3crvTokenIds[1] = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // dai
        alusd3crvTokenIds[2] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // usdc
        alusd3crvTokenIds[3] = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // usdt

        cpa = new CurvePoolAdapter(alusd3crv, alusd3crvTokenIds, true);
        rh = new RevenueHandler(address(veALCX));
        rh.addDebtToken(alusd);
        rh.setDebtToken(dai, alusd);
        rh.setPoolAdapter(dai, address(cpa));
    }

    function testCheckpoint() external {
        uint256 revAmt = 1000e18;
        deal(dai, address(this), revAmt);
        IERC20(dai).transfer(address(rh), revAmt);
        
        uint256 balBefore = IERC20(alusd).balanceOf(address(rh));
        assertEq(balBefore, 0);
        rh.checkpoint();
        uint256 balAfter = IERC20(alusd).balanceOf(address(rh));
        assertApproxEq(balAfter, revAmt, 1e16);

    }

    function testCheckpointRunsOncePerEpoch() external {
        uint256 revAmt = 1000e18;
        // accrue revenue
        deal(dai, address(this), revAmt);
        IERC20(dai).transfer(address(rh), revAmt);
        
        // checkpoint
        rh.checkpoint();
        uint256 balBefore = IERC20(alusd).balanceOf(address(rh));

        // accrue revenue again
        deal(dai, address(this), revAmt);
        IERC20(dai).transfer(address(rh), revAmt);

        // attempt 2nd checkpoint
        rh.checkpoint();
        uint256 balAfter = IERC20(alusd).balanceOf(address(rh));

        assertEq(balBefore, balAfter);
    }

    function testCheckpointMeltsAllRevenue() external {

    }

    function testClaimRevenueOneEpoch() external {

    }

    function testClaimRevenueMultipleEpochs() external {

    }

    function testClaimPartialRevenue() external {

    }

    function testFailClaimRevenueTwice() external {
        
    }
}
