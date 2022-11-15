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
    address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address alusd3crv = 0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c;

    RevenueHandler rh;
    CurvePoolAdapter cpa;

    /// @dev Deploy the contract
    function setUp() public {
        setupBaseTest();
        address[] memory alusd3crvTokenIds = new address[](4);
        alusd3crvTokenIds[0] = 0xBC6DA0FE9aD5f3b0d58160288917AA56653660E9;
        alusd3crvTokenIds[1] = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // dai
        alusd3crvTokenIds[2] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // usdc
        alusd3crvTokenIds[3] = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // usdt

        cpa = new CurvePoolAdapter(alusd3crv, alusd3crvTokenIds, true);
        rh = new RevenueHandler(address(veALCX));
        
        rh.addDebtToken(alusd);

        rh.addRevenueToken(dai);
        rh.setDebtToken(dai, alusd);
        rh.setPoolAdapter(dai, address(cpa));
        
        rh.addRevenueToken(usdc);
        rh.setDebtToken(usdc, alusd);
        rh.setPoolAdapter(usdc, address(cpa));
    }

    function accrueRevenue(address token, uint256 amount) internal {
        deal(token, address(this), amount);
        IERC20(token).transfer(address(rh), amount);
    }

    function testCheckpoint() external {
        uint256 revAmt = 1000e18;
        accrueRevenue(dai, revAmt);
        
        uint256 balBefore = IERC20(alusd).balanceOf(address(rh));
        assertEq(balBefore, 0);
        rh.checkpoint();
        uint256 balAfter = IERC20(alusd).balanceOf(address(rh));
        assertApproxEq(revAmt, balAfter, revAmt/100);
    }

    function testCheckpointRunsOncePerEpoch() external {
        uint256 revAmt = 1000e18;
        accrueRevenue(dai, revAmt);
        
        // checkpoint
        rh.checkpoint();
        uint256 balBefore = IERC20(alusd).balanceOf(address(rh));

        // accrue revenue again
        accrueRevenue(dai, revAmt);

        // attempt 2nd checkpoint
        rh.checkpoint();
        uint256 balAfter = IERC20(alusd).balanceOf(address(rh));

        assertEq(balBefore, balAfter);
    }

    function testCheckpointMeltsAllRevenue() external {
        uint256 revAmt = 1000e18;
        // accrue dai revenue
        accrueRevenue(dai, revAmt);

        uint256 usdcRevAmt = 1000e6;
        // accrue usdc revenue
        accrueRevenue(usdc, usdcRevAmt);
        
        uint256 balBefore = IERC20(alusd).balanceOf(address(rh));
        assertEq(balBefore, 0);
        rh.checkpoint();
        uint256 balAfter = IERC20(alusd).balanceOf(address(rh));
        assertApproxEq(2000e18, balAfter, 2000e18/100);
    }

    function testClaimRevenueOneEpoch() external {
        veALCX.checkpoint();
        
        uint256 lockAmt = 10e18;
        deal(address(bpt), address(this), lockAmt);
        IERC20(bpt).approve(address(veALCX), lockAmt);
        uint256 tokenId = veALCX.createLock(lockAmt, MAXTIME, false);

        rh.checkpoint();
        uint256 revAmt = 1000e18;
        
        // jump 1 epoch
        hevm.warp(block.timestamp + 604801);
        hevm.roll(block.number + 50400);

        accrueRevenue(dai, revAmt);
        rh.checkpoint();
        
        // jump 1 epoch
        hevm.warp(block.timestamp + 604801);
        hevm.roll(block.number + 50400);

        uint256 claimable = rh.claimable(tokenId, alusd);
        assertApproxEq(revAmt, claimable, revAmt/100);
    }

    // function testClaimRevenueMultipleEpochs() external {

    // }

    // function testClaimPartialRevenue() external {

    // }

    // function testFailClaimRevenueTwice() external {
        
    // }
}
