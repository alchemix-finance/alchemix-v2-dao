// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "./BaseTest.sol";
import "src/CurveMetaPoolAdapter.sol";
import "src/CurveEthPoolAdapter.sol";
import "lib/v2-foundry/src/interfaces/IAlchemistV2.sol";
import "lib/v2-foundry/src/interfaces/IWhitelist.sol";

contract RevenueHandlerTest is BaseTest {
    uint256 ONE_EPOCH_TIME = 1 weeks;
    uint256 ONE_EPOCH_BLOCKS = (1 weeks) / 12;

    IAlchemistV2 public alusdAlchemist = IAlchemistV2(0x5C6374a2ac4EBC38DeA0Fc1F8716e5Ea1AdD94dd);
    IWhitelist public whitelist = IWhitelist(0x78537a6CeBa16f412E123a90472C6E0e9A8F1132);

    // RevenueHandler revenueHandler;
    CurveMetaPoolAdapter cpa;

    /// @dev Deploy the contract
    function setUp() public {
        setupContracts(block.timestamp);

        address[] memory alusd3crvTokenIds = new address[](4);
        alusd3crvTokenIds[0] = alusd;
        alusd3crvTokenIds[1] = dai; // dai
        alusd3crvTokenIds[2] = usdc; // usdc
        alusd3crvTokenIds[3] = usdt; // usdt

        cpa = new CurveMetaPoolAdapter(alusd3crv, alusd3crvTokenIds);
        revenueHandler = new RevenueHandler(address(veALCX));

        revenueHandler.addDebtToken(alusd);

        revenueHandler.addRevenueToken(dai);
        revenueHandler.setDebtToken(dai, alusd);
        revenueHandler.setPoolAdapter(dai, address(cpa));

        revenueHandler.addRevenueToken(usdc);
        revenueHandler.setDebtToken(usdc, alusd);
        revenueHandler.setPoolAdapter(usdc, address(cpa));

        hevm.prank(devmsig);
        whitelist.disable();
    }

    /*
        Internal helper functions
    */

    function _accrueRevenue(address token, uint256 amount) internal {
        deal(token, address(this), amount);
        IERC20(token).transfer(address(revenueHandler), amount);
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

    function _initializeVeALCXPosition(uint256 lockAmt) internal returns (uint256 tokenId) {
        veALCX.checkpoint();
        tokenId = _lockVeALCX(lockAmt);
    }

    function _accrueRevenueAndJumpOneEpoch(uint256 revAmt) internal {
        revenueHandler.checkpoint();

        _jumpOneEpoch();

        _accrueRevenue(dai, revAmt);
        revenueHandler.checkpoint();

        _jumpOneEpoch();
    }

    function _setupClaimableRevenue(uint256 revAmt) internal returns (uint256 tokenId) {
        tokenId = _initializeVeALCXPosition(10e18);

        _accrueRevenueAndJumpOneEpoch(revAmt);
    }

    function _takeDebt(uint256 amount) internal {
        deal(dai, address(this), 3 * amount);
        IERC20(dai).approve(address(alusdAlchemist), 3 * amount);
        alusdAlchemist.depositUnderlying(ydai, 3 * amount, address(this), 0);
        alusdAlchemist.mint(amount, address(this));
    }

    /*
        Admin Function Tests
    */

    function testAddDebtToken() external {
        revenueHandler.addDebtToken(aleth);
        address debtToken = revenueHandler.debtTokens(1);
        assertEq(debtToken, aleth);
    }

    function testRemoveDebtToken() external {
        revenueHandler.addDebtToken(aleth);
        revenueHandler.removeDebtToken(aleth);
        hevm.expectRevert();
        revenueHandler.debtTokens(1);
    }

    function testAddDebtTokenFail() external {
        revenueHandler.addDebtToken(aleth);
        expectError("debt token already exists");
        revenueHandler.addDebtToken(aleth);
    }

    function testRemoveDebtTokenFail() external {
        revenueHandler.addDebtToken(aleth);
        revenueHandler.removeDebtToken(aleth);
        expectError("debt token does not exist");
        revenueHandler.removeDebtToken(aleth);
    }

    function testAddRevenueToken() external {
        revenueHandler.addRevenueToken(address(weth));
        address debtToken = revenueHandler.revenueTokens(2);
        assertEq(debtToken, address(weth));
    }

    function testRemoveRevenueToken() external {
        revenueHandler.addRevenueToken(address(weth));
        revenueHandler.removeRevenueToken(address(weth));
        hevm.expectRevert();
        revenueHandler.revenueTokens(2);
    }

    function testAddRevenueTokenFail() external {
        revenueHandler.addRevenueToken(address(weth));
        expectError("revenue token already exists");
        revenueHandler.addRevenueToken(address(weth));
    }

    function testRemoveRevenueTokenFail() external {
        revenueHandler.addRevenueToken(address(weth));
        revenueHandler.removeRevenueToken(address(weth));
        expectError("revenue token does not exist");
        revenueHandler.removeRevenueToken(address(weth));
    }

    function testSetDebtToken() external {
        revenueHandler.addDebtToken(aleth);
        revenueHandler.addRevenueToken(address(weth));
        revenueHandler.setDebtToken(address(weth), aleth);
        (address debtToken, , ) = revenueHandler.revenueTokenConfigs(address(weth));
        assertEq(debtToken, aleth);
    }

    function testSetPoolAdapter() external {
        revenueHandler.addDebtToken(aleth);
        revenueHandler.addRevenueToken(address(weth));
        revenueHandler.setPoolAdapter(address(weth), alusd3crv);
        (, address poolAdapter, ) = revenueHandler.revenueTokenConfigs(address(weth));
        assertEq(poolAdapter, alusd3crv);
    }

    /*
        User Function Tests
    */

    function testCheckpoint() external {
        uint256 revAmt = 1000e18;
        _accrueRevenue(dai, revAmt);

        uint256 balBefore = IERC20(alusd).balanceOf(address(revenueHandler));
        assertEq(balBefore, 0);
        revenueHandler.checkpoint();
        uint256 balAfter = IERC20(alusd).balanceOf(address(revenueHandler));
        assertApproxEq(revAmt, balAfter, revAmt / 65);
    }

    function testCheckpointRunsOncePerEpoch() external {
        uint256 revAmt = 1000e18;
        _accrueRevenue(dai, revAmt);

        revenueHandler.checkpoint();
        uint256 balBefore = IERC20(alusd).balanceOf(address(revenueHandler));

        // accrue revenue again
        _accrueRevenue(dai, revAmt);

        // attempt 2nd checkpoint
        revenueHandler.checkpoint();
        uint256 balAfter = IERC20(alusd).balanceOf(address(revenueHandler));

        assertEq(balBefore, balAfter);
    }

    function testCheckpointMeltsAllRevenue() external {
        uint256 revAmt = 1000e18;
        _accrueRevenue(dai, revAmt);

        uint256 usdcRevAmt = 1000e6;
        _accrueRevenue(usdc, usdcRevAmt);

        uint256 balBefore = IERC20(alusd).balanceOf(address(revenueHandler));
        assertEq(balBefore, 0);
        revenueHandler.checkpoint();
        uint256 balAfter = IERC20(alusd).balanceOf(address(revenueHandler));
        assertApproxEq(2000e18, balAfter, 2000e18 / uint256(65));
    }

    function testClaimOnlyApproved() external {
        uint256 revAmt = 1000e18;
        uint256 tokenId = _setupClaimableRevenue(revAmt);
        uint256 claimable = revenueHandler.claimable(tokenId, alusd);
        hevm.prank(holder);
        expectError("Not approved or owner");
        revenueHandler.claim(tokenId, address(alusdAlchemist), claimable, address(this));
    }

    function testClaimRevenueOneEpoch() external {
        uint256 revAmt = 1000e18;
        uint256 tokenId = _setupClaimableRevenue(revAmt);

        uint256 claimable = revenueHandler.claimable(tokenId, alusd);
        assertApproxEq(revAmt, claimable, revAmt / 65);

        uint256 debtAmt = 5000e18;
        _takeDebt(debtAmt);

        revenueHandler.claim(tokenId, address(alusdAlchemist), claimable, address(this));
        (int256 finalDebt, ) = alusdAlchemist.accounts(address(this));
        assertEq(debtAmt - claimable, uint256(finalDebt));
    }

    function testClaimRevenueMultipleEpochs() external {
        uint256 revAmt = 1000e18;
        uint256 tokenId = _setupClaimableRevenue(revAmt);

        _accrueRevenue(dai, revAmt);
        revenueHandler.checkpoint();

        _jumpOneEpoch();

        uint256 claimable = revenueHandler.claimable(tokenId, alusd);
        assertApproxEq(revAmt * 2, claimable, (revAmt * 2) / 65);

        uint256 debtAmt = 5000e18;
        _takeDebt(debtAmt);

        revenueHandler.claim(tokenId, address(alusdAlchemist), claimable, address(this));
        (int256 finalDebt, ) = alusdAlchemist.accounts(address(this));
        assertEq(debtAmt - claimable, uint256(finalDebt));
    }

    function testClaimPartialRevenue() external {
        uint256 revAmt = 1000e18;
        uint256 tokenId = _setupClaimableRevenue(revAmt);

        uint256 claimAmt = 200e18;

        uint256 debtAmt = 5000e18;
        _takeDebt(debtAmt);

        revenueHandler.claim(tokenId, address(alusdAlchemist), claimAmt, address(this));
        (int256 currentDebt, ) = alusdAlchemist.accounts(address(this));
        assertApproxEq(debtAmt - (claimAmt), uint256(currentDebt), 1);

        revenueHandler.claim(tokenId, address(alusdAlchemist), claimAmt, address(this));
        (int256 finalDebt, ) = alusdAlchemist.accounts(address(this));
        assertApproxEq(debtAmt - (2 * claimAmt), uint256(finalDebt), 1);
    }

    function testClaimTooMuch() external {
        uint256 revAmt = 1000e18;
        uint256 tokenId = _setupClaimableRevenue(revAmt);

        uint256 claimable = revenueHandler.claimable(tokenId, alusd);

        uint256 debtAmt = 5000e18;
        _takeDebt(debtAmt);

        revenueHandler.claim(tokenId, address(alusdAlchemist), claimable / 2, address(this));

        expectError("Not enough claimable");
        revenueHandler.claim(tokenId, address(alusdAlchemist), claimable, address(this));

        uint256 finalClaimable = revenueHandler.claimable(tokenId, alusd);
        assertApproxEq(claimable / 2, finalClaimable, 1);
    }

    function testClaimMoreThanDebt() external {
        uint256 revAmt = 1000e18;
        uint256 tokenId = _setupClaimableRevenue(revAmt);

        uint256 claimable = revenueHandler.claimable(tokenId, alusd);

        uint256 debtAmt = claimable / 2;
        _takeDebt(debtAmt);

        uint256 balBefore = IERC20(alusd).balanceOf(address(this));
        revenueHandler.claim(tokenId, address(alusdAlchemist), claimable, address(this));
        uint256 balAfter = IERC20(alusd).balanceOf(address(this));

        assertApproxEq(debtAmt, balAfter - balBefore, 1);
    }

    function testFirstClaimLate() external {
        // The user has had a veALCX position for multiple epochs, but has not yet claimed any revenue.
        // The user should be able to claim all the revenue they are entitled to since they initialized their veALCX position.
        uint256 revAmt = 1000e18;
        _accrueRevenueAndJumpOneEpoch(revAmt);
        uint256 lockAmt = 10e18;
        uint256 tokenId = _initializeVeALCXPosition(lockAmt);
        _accrueRevenueAndJumpOneEpoch(revAmt);
        _jumpOneEpoch();
        uint256 claimable = revenueHandler.claimable(tokenId, alusd);
        assertApproxEq(claimable, revAmt, revAmt / 65);
    }

    function testClaimBeforeAndAfterCheckpoint() external {
        uint256 debtAmt = 5000e18;
        _takeDebt(debtAmt);

        uint256 revAmt = 1000e18;
        uint256 lockAmt = 10e18;
        uint256 tokenId = _initializeVeALCXPosition(lockAmt);
        _accrueRevenueAndJumpOneEpoch(revAmt);
        // this revenue is not yet checkpointed
        _accrueRevenue(dai, revAmt);
        uint256 claimable = revenueHandler.claimable(tokenId, alusd);
        assertApproxEq(claimable, revAmt, revAmt / 65);

        revenueHandler.claim(tokenId, address(alusdAlchemist), claimable, address(this));

        claimable = revenueHandler.claimable(tokenId, alusd);
        assertEq(claimable, 0);

        // checkpoint the accrued revenue
        revenueHandler.checkpoint();
        claimable = revenueHandler.claimable(tokenId, alusd);
        assertApproxEq(claimable, revAmt, revAmt / 65);
    }

    function testIncreaseVeALCXBeforeFirstClaim() external {
        // The user has had a veALCX position for an epoch, increase their position (checkpointed
        //      their veALCX position), but has not yet claimed any revenue.
        // The user should be able to claim all the revenue they are entitled to since they initialized their veALCX position.
        uint256 revAmt = 1000e18;
        _accrueRevenueAndJumpOneEpoch(revAmt); // this revenue should NOT be claimable

        uint256 lockAmt = 10e18;
        uint256 tokenId = _initializeVeALCXPosition(lockAmt);

        _accrueRevenueAndJumpOneEpoch(revAmt); // this revenue SHOULD be claimable

        deal(address(bpt), address(this), lockAmt);
        IERC20(bpt).approve(address(veALCX), lockAmt);
        veALCX.increaseAmount(tokenId, lockAmt);

        _accrueRevenueAndJumpOneEpoch(revAmt); // this revenue SHOULD be claimable

        uint256 claimable = revenueHandler.claimable(tokenId, alusd);
        assertApproxEq(claimable, 2 * revAmt, (2 * revAmt) / 65);
    }

    function testCheckpointETH() external {
        address[] memory alethCrvTokenIds = new address[](2);
        alethCrvTokenIds[0] = address(weth); // eth
        alethCrvTokenIds[1] = aleth;

        CurveEthPoolAdapter alethCpa = new CurveEthPoolAdapter(alethcrv, alethCrvTokenIds, address(weth));

        revenueHandler.addDebtToken(aleth);

        revenueHandler.addRevenueToken(address(weth));
        revenueHandler.setDebtToken(address(weth), aleth);
        revenueHandler.setPoolAdapter(address(weth), address(alethCpa));

        uint256 revAmt = 10e18;
        _accrueRevenue(address(weth), revAmt);

        uint256 balBefore = IERC20(aleth).balanceOf(address(revenueHandler));
        assertEq(balBefore, 0);
        revenueHandler.checkpoint();
        uint256 balAfter = IERC20(aleth).balanceOf(address(revenueHandler));
        assertApproxEq(revAmt, balAfter, revAmt / 55);
    }

    function testMultipleClaimers() external {
        uint256 debtAmt = 5000e18;
        _takeDebt(debtAmt);

        deal(dai, holder, 3 * debtAmt);
        hevm.startPrank(holder);
        IERC20(dai).approve(address(alusdAlchemist), 3 * debtAmt);
        alusdAlchemist.depositUnderlying(ydai, 3 * debtAmt, holder, 0);
        alusdAlchemist.mint(debtAmt, holder);
        hevm.stopPrank();

        uint256 lockAmt = 10e18;
        uint256 tokenId = _initializeVeALCXPosition(lockAmt);

        hevm.startPrank(holder);
        veALCX.checkpoint();
        uint256 holderLockAmt = 40e18;
        deal(address(bpt), holder, holderLockAmt);
        IERC20(bpt).approve(address(veALCX), holderLockAmt);
        uint256 holderTokenId = veALCX.createLock(holderLockAmt, MAXTIME, false);
        hevm.stopPrank();

        uint256 revAmt = 5000e18;
        _accrueRevenueAndJumpOneEpoch(revAmt);

        uint256 claimable = revenueHandler.claimable(tokenId, alusd);
        assertApproxEq(claimable, revAmt / 5, (revAmt / 5) / 10);
        revenueHandler.claim(tokenId, address(alusdAlchemist), claimable, address(this));

        _accrueRevenueAndJumpOneEpoch(revAmt);
        uint256 holderClaimable = revenueHandler.claimable(holderTokenId, alusd);
        assertApproxEq(holderClaimable, (2 * revAmt * 4) / 5, ((2 * revAmt * 4) / 5) / 65);

        hevm.startPrank(holder);
        revenueHandler.claim(holderTokenId, address(alusdAlchemist), holderClaimable, holder);
        hevm.stopPrank();

        claimable = revenueHandler.claimable(tokenId, alusd);
        revenueHandler.claim(tokenId, address(alusdAlchemist), claimable, address(this));

        uint256 bal = IERC20(alusd).balanceOf(address(revenueHandler));
        assertApproxEq(bal, 0, 10); // maybe dust
    }

    function testDisableRevenueToken() external {
        uint256 revAmt = 1000e18;
        _accrueRevenue(dai, revAmt);

        uint256 balBefore = IERC20(alusd).balanceOf(address(revenueHandler));
        assertEq(balBefore, 0);
        revenueHandler.disableRevenueToken(dai);
        revenueHandler.checkpoint();
        uint256 balAfter = IERC20(alusd).balanceOf(address(revenueHandler));
        assertEq(balBefore, balAfter);
    }
}
