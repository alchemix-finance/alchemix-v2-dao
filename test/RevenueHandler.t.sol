// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./BaseTest.sol";
import "../src/RevenueHandler.sol";
import "../src/CurvePoolAdapter.sol";
import "./utils/DSTestPlus.sol";
import "../lib/v2-foundry/src/interfaces/IAlchemistV2.sol";
import "../lib/v2-foundry/src/interfaces/IWhitelist.sol";

contract RevenueHandlerTest is BaseTest {
    uint256 ONE_EPOCH_TIME = 1 weeks;
    uint256 ONE_EPOCH_BLOCKS = (1 weeks) / 12;
    address holder = 0x000000000000000000000000000000000000dEaD;
    address alusd = 0xBC6DA0FE9aD5f3b0d58160288917AA56653660E9;
    address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address aleth = 0x0100546F2cD4C9D97f798fFC9755E47865FF7Ee6;
    address alusd3crv = 0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c;
    IAlchemistV2 public alusdAlchemist = IAlchemistV2(0x5C6374a2ac4EBC38DeA0Fc1F8716e5Ea1AdD94dd);
    IWhitelist public whitelist = IWhitelist(0x78537a6CeBa16f412E123a90472C6E0e9A8F1132);

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

        hevm.prank(devmsig);
        whitelist.disable();
    }

    /*
        Internal helper functions
    */

    function _accrueRevenue(address token, uint256 amount) internal {
        deal(token, address(this), amount);
        IERC20(token).transfer(address(rh), amount);
    }

    function _lockVeALCX(uint256 amount) internal returns (uint256) {
        deal(address(bpt), address(this), amount);
        IERC20(bpt).approve(address(veALCX), amount);
        return veALCX.createLock(amount, MAXTIME, false);
    }

    function _jumpOneEpoch() internal {
        hevm.warp(block.timestamp + ONE_EPOCH_TIME + 1);
        hevm.roll(block.number + ONE_EPOCH_BLOCKS);
    }

    function _initializeVeALCXPosition() internal returns (uint256 tokenId) {
        veALCX.checkpoint();
        uint256 lockAmt = 10e18;
        tokenId = _lockVeALCX(lockAmt);
    }

    function _accrueRevenueAndJumpOneEpoch(uint256 revAmt) internal {
        rh.checkpoint();
        
        _jumpOneEpoch();

        _accrueRevenue(dai, revAmt);
        rh.checkpoint();
        
        _jumpOneEpoch();
    }

    function _setupClaimableRevenue(uint256 revAmt) internal returns (uint256 tokenId) {
        tokenId = _initializeVeALCXPosition();

        _accrueRevenueAndJumpOneEpoch(revAmt);
    }

    function _takeDebt(uint256 amount) internal {
        deal(dai, address(this), 3 * amount);
        IERC20(dai).approve(address(alusdAlchemist), 3 * amount);
        alusdAlchemist.depositUnderlying(ydai, 3 * amount, address(this), 0);
        alusdAlchemist.mint(amount, address(this));
        hevm.stopPrank();
    }

    /*
        Admin Function Tests
    */

    function testAddDebtToken() external {
        rh.addDebtToken(aleth);
        address debtToken = rh.debtTokens(1);
        assertEq(debtToken, aleth);
    }

    function testRemoveDebtToken() external {
        rh.addDebtToken(aleth);
        rh.removeDebtToken(aleth);
        hevm.expectRevert();
        rh.debtTokens(1);
    }

    function testAddDebtTokenFail() external {
        rh.addDebtToken(aleth);
        expectError("debt token already exists");
        rh.addDebtToken(aleth);
    }

    function testRemoveDebtTokenFail() external {
        rh.addDebtToken(aleth);
        rh.removeDebtToken(aleth);
        expectError("debt token does not exist");
        rh.removeDebtToken(aleth);
    }

    function testAddRevenueToken() external {
        rh.addRevenueToken(address(weth));
        address debtToken = rh.revenueTokens(2);
        assertEq(debtToken, address(weth));
    }

    function testRemoveRevenueToken() external {
        rh.addRevenueToken(address(weth));
        rh.removeRevenueToken(address(weth));
        hevm.expectRevert();
        rh.revenueTokens(2);
    }

    function testAddRevenueTokenFail() external {
        rh.addRevenueToken(address(weth));
        expectError("revenue token already exists");
        rh.addRevenueToken(address(weth));
    }

    function testRemoveRevenueTokenFail() external {
        rh.addRevenueToken(address(weth));
        rh.removeRevenueToken(address(weth));
        expectError("revenue token does not exist");
        rh.removeRevenueToken(address(weth));
    }

    function testSetDebtToken() external {
        rh.addDebtToken(aleth);
        rh.addRevenueToken(address(weth));
        rh.setDebtToken(address(weth), aleth);
        (address debtToken, ) = rh.revenueTokenConfigs(address(weth));
        assertEq(debtToken, aleth);
    }

    function testSetPoolAdapter() external {
        rh.addDebtToken(aleth);
        rh.addRevenueToken(address(weth));
        rh.setPoolAdapter(address(weth), alusd3crv);
        (, address poolAdapter) = rh.revenueTokenConfigs(address(weth));
        assertEq(poolAdapter, alusd3crv);
    }

    /*
        User Function Tests
    */

    function testCheckpoint() external {
        uint256 revAmt = 1000e18;
        _accrueRevenue(dai, revAmt);
        
        uint256 balBefore = IERC20(alusd).balanceOf(address(rh));
        assertEq(balBefore, 0);
        rh.checkpoint();
        uint256 balAfter = IERC20(alusd).balanceOf(address(rh));
        assertApproxEq(revAmt, balAfter, revAmt/100);
    }

    function testCheckpointRunsOncePerEpoch() external {
        uint256 revAmt = 1000e18;
        _accrueRevenue(dai, revAmt);
        
        rh.checkpoint();
        uint256 balBefore = IERC20(alusd).balanceOf(address(rh));

        // accrue revenue again
        _accrueRevenue(dai, revAmt);

        // attempt 2nd checkpoint
        rh.checkpoint();
        uint256 balAfter = IERC20(alusd).balanceOf(address(rh));

        assertEq(balBefore, balAfter);
    }

    function testCheckpointMeltsAllRevenue() external {
        uint256 revAmt = 1000e18;
        _accrueRevenue(dai, revAmt);

        uint256 usdcRevAmt = 1000e6;
        _accrueRevenue(usdc, usdcRevAmt);
        
        uint256 balBefore = IERC20(alusd).balanceOf(address(rh));
        assertEq(balBefore, 0);
        rh.checkpoint();
        uint256 balAfter = IERC20(alusd).balanceOf(address(rh));
        assertApproxEq(2000e18, balAfter, 2000e18/100);
    }

    function testClaimOnlyApproved() external {
        uint256 revAmt = 1000e18;
        uint256 tokenId = _setupClaimableRevenue(revAmt);
        uint256 claimable = rh.claimable(tokenId, alusd);
        hevm.prank(holder);
        expectError("not approved or owner");
        rh.claim(tokenId, address(alusdAlchemist), claimable, address(this));
    }

    function testClaimRevenueOneEpoch() external {
        uint256 revAmt = 1000e18;
        uint256 tokenId = _setupClaimableRevenue(revAmt);

        uint256 claimable = rh.claimable(tokenId, alusd);
        assertApproxEq(revAmt, claimable, revAmt/100);

        uint256 debtAmt = 5000e18;
        _takeDebt(debtAmt);

        rh.claim(tokenId, address(alusdAlchemist), claimable, address(this));
        (int256 finalDebt, ) = alusdAlchemist.accounts(address(this));
        assertEq(debtAmt - claimable, uint256(finalDebt));
    }

    function testClaimRevenueMultipleEpochs() external {
        uint256 revAmt = 1000e18;
        uint256 tokenId = _setupClaimableRevenue(revAmt);

        _accrueRevenue(dai, revAmt);
        rh.checkpoint();
        
        _jumpOneEpoch();

        uint256 claimable = rh.claimable(tokenId, alusd);
        assertApproxEq(revAmt * 2, claimable, revAmt * 2 /100);

        uint256 debtAmt = 5000e18;
        _takeDebt(debtAmt);

        rh.claim(tokenId, address(alusdAlchemist), claimable, address(this));
        (int256 finalDebt, ) = alusdAlchemist.accounts(address(this));
        assertEq(debtAmt - claimable, uint256(finalDebt));
    }

    function testClaimPartialRevenue() external {
        uint256 revAmt = 1000e18;
        uint256 tokenId = _setupClaimableRevenue(revAmt);

        uint256 claimable = rh.claimable(tokenId, alusd);

        uint256 debtAmt = 5000e18;
        _takeDebt(debtAmt);

        rh.claim(tokenId, address(alusdAlchemist), claimable / 2, address(this));
        (int256 currentDebt, ) = alusdAlchemist.accounts(address(this));
        assertApproxEq(debtAmt - (claimable / 2), uint256(currentDebt), 1);

        rh.claim(tokenId, address(alusdAlchemist), claimable / 2, address(this));
        (int256 finalDebt, ) = alusdAlchemist.accounts(address(this));
        assertApproxEq(debtAmt - claimable, uint256(finalDebt), 1);
    }

    function testClaimTooMuch() external {
        uint256 revAmt = 1000e18;
        uint256 tokenId = _setupClaimableRevenue(revAmt);

        uint256 claimable = rh.claimable(tokenId, alusd);

        uint256 debtAmt = 5000e18;
        _takeDebt(debtAmt);

        rh.claim(tokenId, address(alusdAlchemist), claimable / 2, address(this));

        expectError("Not enough claimable");
        rh.claim(tokenId, address(alusdAlchemist), claimable, address(this));

        uint256 finalClaimable = rh.claimable(tokenId, alusd);
        assertApproxEq(claimable / 2, finalClaimable, 1);
    }

    function testClaimMoreThanDebt() external {
        uint256 revAmt = 1000e18;
        uint256 tokenId = _setupClaimableRevenue(revAmt);

        uint256 claimable = rh.claimable(tokenId, alusd);

        uint256 debtAmt = claimable / 2;
        _takeDebt(debtAmt);
        
        uint256 balBefore = IERC20(alusd).balanceOf(address(this));
        rh.claim(tokenId, address(alusdAlchemist), claimable, address(this));
        uint256 balAfter = IERC20(alusd).balanceOf(address(this));

        assertApproxEq(debtAmt, balAfter - balBefore, 1);
    }

    function testFirstClaimLate() external {
        // The user has had a veALCX position for multiple epochs, but has not yet claimed any revenue.
        // The user should be able to claim all the revenue they are entitled to since they initialized their veALCX position.
        uint256 revAmt = 1000e18;
        _accrueRevenueAndJumpOneEpoch(revAmt);
        uint256 tokenId = _initializeVeALCXPosition();
        _accrueRevenueAndJumpOneEpoch(revAmt);
        _jumpOneEpoch();
        uint256 claimable = rh.claimable(tokenId, alusd);
        assertApproxEq(claimable, revAmt, revAmt/100);
    }

    function testClaimBeforeAndAfterCheckpoint() external {
        uint256 debtAmt = 5000e18;
        _takeDebt(debtAmt);

        uint256 revAmt = 1000e18;
        uint256 tokenId = _initializeVeALCXPosition();
        _accrueRevenueAndJumpOneEpoch(revAmt);
        // this revenue is not yet checkpointed
        _accrueRevenue(dai, revAmt);
        uint256 claimable = rh.claimable(tokenId, alusd);
        assertApproxEq(claimable, revAmt, revAmt/100);

        rh.claim(tokenId, address(alusdAlchemist), claimable, address(this));

        claimable = rh.claimable(tokenId, alusd);
        assertEq(claimable, 0);
        
        // checkpoint the accrued revenue
        rh.checkpoint();
        claimable = rh.claimable(tokenId, alusd);
        assertApproxEq(claimable, revAmt, revAmt/100);
    }
}
