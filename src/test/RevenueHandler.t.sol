// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "./BaseTest.sol";
import "src/CurveMetaPoolAdapter.sol";
import "src/CurveEthPoolAdapter.sol";
import "lib/v2-foundry/src/interfaces/IAlchemistV2.sol";
import "lib/v2-foundry/src/interfaces/IWhitelist.sol";

contract RevenueHandlerTest is BaseTest {
    uint256 ONE_EPOCH_TIME = 2 weeks;
    uint256 ONE_EPOCH_BLOCKS = (2 weeks) / 12;
    uint256 DELTA = 65;

    IAlchemistV2 public alusdAlchemist = IAlchemistV2(0x5C6374a2ac4EBC38DeA0Fc1F8716e5Ea1AdD94dd);
    IAlchemistV2 public alethAlchemist = IAlchemistV2(0x062Bf725dC4cDF947aa79Ca2aaCCD4F385b13b5c);
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

        hevm.prank(admin);
        revenueHandler.transferOwnership(address(this));

        revenueHandler.addRevenueToken(dai);
        revenueHandler.setDebtToken(dai, alusd);
        revenueHandler.setPoolAdapter(dai, address(cpa));

        revenueHandler.addRevenueToken(usdc);
        revenueHandler.setDebtToken(usdc, alusd);
        revenueHandler.setPoolAdapter(usdc, address(cpa));

        revenueHandler.addRevenueToken(bal);
        revenueHandler.addAlchemicToken(address(alusdAlchemist));

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

    function _accrueNonAlchemicRevenueAndJumpOneEpoch(uint256 revAmt, address token) internal {
        revenueHandler.checkpoint();

        _jumpOneEpoch();

        _accrueRevenue(token, revAmt);
        revenueHandler.checkpoint();

        _jumpOneEpoch();
    }

    function _setupClaimableRevenue(uint256 revAmt) internal returns (uint256 tokenId) {
        tokenId = _initializeVeALCXPosition(10e18);

        _accrueRevenueAndJumpOneEpoch(revAmt);
    }

    function _setupClaimableNonAlchemicRevenue(uint256 revAmt, address token) internal returns (uint256 tokenId) {
        tokenId = _initializeVeALCXPosition(10e18);

        _accrueNonAlchemicRevenueAndJumpOneEpoch(revAmt, token);
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

    function testAddRevenueToken() external {
        revenueHandler.addRevenueToken(address(weth));
        address debtToken = revenueHandler.revenueTokens(3);
        assertEq(debtToken, address(weth));
    }

    function testRemoveRevenueToken() external {
        revenueHandler.addRevenueToken(address(weth));
        revenueHandler.removeRevenueToken(address(weth));
        hevm.expectRevert();
        revenueHandler.revenueTokens(3);
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

    function testAddAlchemicToken() external {
        revenueHandler.addAlchemicToken(address(alethAlchemist));
        address alchemicToken = revenueHandler.alchemists(address(alethAlchemist));
        assertEq(alchemicToken, aleth);
    }

    function testAddAlchemicTokenFail() external {
        revenueHandler.addAlchemicToken(address(alethAlchemist));
        expectError("alchemic token already exists");
        revenueHandler.addAlchemicToken(address(alethAlchemist));
    }

    function testRemoveAlchemicToken() external {
        revenueHandler.addAlchemicToken(address(alethAlchemist));
        revenueHandler.removeAlchemicToken(address(alethAlchemist));
        address alchemicToken = revenueHandler.alchemists(address(alethAlchemist));
        assertEq(alchemicToken, address(0));
    }

    function testRemoveAlchemicTokenFail() external {
        revenueHandler.addAlchemicToken(address(alethAlchemist));
        revenueHandler.removeAlchemicToken(address(alethAlchemist));
        expectError("alchemic token does not exist");
        revenueHandler.removeAlchemicToken(address(alethAlchemist));
    }

    function testSetDebtToken() external {
        revenueHandler.addRevenueToken(address(weth));
        revenueHandler.setDebtToken(address(weth), aleth);
        (address debtToken, , ) = revenueHandler.revenueTokenConfigs(address(weth));
        assertEq(debtToken, aleth);
    }

    function testSetPoolAdapter() external {
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
        assertApproxEq(revAmt, balAfter, revAmt / DELTA);
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
        assertApproxEq(2000e18, balAfter, 2000e18 / uint256(DELTA));
    }

    function testClaimOnlyApproved() external {
        uint256 revAmt = 1000e18;
        uint256 tokenId = _setupClaimableRevenue(revAmt);
        uint256 claimable = revenueHandler.claimable(tokenId, alusd);
        hevm.prank(holder);
        expectError("Not approved or owner");
        revenueHandler.claim(tokenId, alusd, address(alusdAlchemist), claimable, address(this));
    }

    function testClaimBeforeEpoch() external {
        uint256 revAmt = 1000e18;
        _accrueRevenue(dai, revAmt);

        uint256 tokenId1 = _lockVeALCX(10e18);

        hevm.warp(block.timestamp + 6 days);

        uint256 tokenId2 = _lockVeALCX(10e18);

        uint256 period = minter.activePeriod();

        uint256 revenueHandlerBalance1 = IERC20(dai).balanceOf(address(revenueHandler));
        assertEq(revenueHandlerBalance1, revAmt, "should be equal to revAmt");

        uint256 claimable = revenueHandler.claimable(tokenId1, alusd);
        assertEq(claimable, 0, "claimable should be 0");

        hevm.expectRevert(abi.encodePacked("Amount must be greater than 0"));
        revenueHandler.claim(tokenId1, alusd, address(alusdAlchemist), claimable, address(this));

        hevm.warp(period + nextEpoch);
        voter.distribute();

        claimable = revenueHandler.claimable(tokenId1, alusd);
        uint256 claimable2 = revenueHandler.claimable(tokenId2, alusd);

        assertGt(claimable2, claimable, "earlier veALCX should have more claimable");

        revenueHandler.claim(tokenId1, alusd, address(alusdAlchemist), claimable / 2, address(this));

        assertEq(IERC20(alusd).balanceOf(address(this)), claimable / 2, "should be equal to amount claimed");
    }

    function testClaimRevenueOneEpoch() external {
        revenueHandler.addAlchemicToken(address(alethAlchemist));

        uint256 revAmt = 1000e18;
        uint256 tokenId = _setupClaimableRevenue(revAmt);

        uint256 claimable = revenueHandler.claimable(tokenId, alusd);

        assertApproxEq(revAmt, claimable, revAmt / DELTA);

        uint256 debtAmt = 5000e18;
        _takeDebt(debtAmt);

        hevm.expectRevert(abi.encodePacked("Invalid alchemist/alchemic-token pair"));
        revenueHandler.claim(tokenId, alusd, address(alethAlchemist), claimable, address(this));

        revenueHandler.claim(tokenId, alusd, address(alusdAlchemist), claimable, address(this));

        (int256 finalDebt, ) = alusdAlchemist.accounts(address(this));
        assertApproxEq(debtAmt - claimable, uint256(finalDebt), uint256(finalDebt) / DELTA);
    }

    function testClaimNonAlchemicRevenue() external {
        uint256 revAmt = 1000e18;
        uint256 tokenId = _setupClaimableNonAlchemicRevenue(revAmt, bal);
        uint256 balBefore = IERC20(bal).balanceOf(address(this));

        assertEq(balBefore, 0, "should have no bal before claiming");

        uint256 claimable = revenueHandler.claimable(tokenId, bal);

        revenueHandler.claim(tokenId, bal, address(0), claimable, address(this));

        uint256 balAfter = IERC20(bal).balanceOf(address(this));

        assertEq(balAfter, claimable, "should be equal to amount claimed");
    }

    function testNotEnoughRevenueToClaim() external {
        uint256 revAmt = 1000e18;
        uint256 tokenId = _setupClaimableNonAlchemicRevenue(revAmt, bal);
        uint256 balBefore = IERC20(bal).balanceOf(address(this));

        assertEq(balBefore, 0, "should have no bal before claiming");

        uint256 claimable = revenueHandler.claimable(tokenId, bal);

        hevm.prank(address(revenueHandler));
        IERC20(bal).transfer(admin, claimable);

        hevm.expectRevert(abi.encodePacked("Not enough revenue to claim"));
        revenueHandler.claim(tokenId, bal, address(0), claimable, address(this));
    }

    function testClaimNonApprovedRevenue() external {
        uint256 revAmt = 1000e18;
        uint256 tokenId = _setupClaimableNonAlchemicRevenue(revAmt, aura);
        uint256 balBefore = IERC20(aura).balanceOf(address(this));
        uint256 revenueHandlerAuraBal = IERC20(aura).balanceOf(address(revenueHandler));

        assertEq(revenueHandlerAuraBal, revAmt, "should be equal to revAmt");
        assertEq(balBefore, 0, "should have no aura before claiming");

        uint256 claimableBefore = revenueHandler.claimable(tokenId, aura);

        assertEq(claimableBefore, 0, "claimable should be 0 before token is added to revenueHandler");

        revenueHandler.addRevenueToken(aura);

        uint256 claimableAfter = revenueHandler.claimable(tokenId, aura);

        assertEq(claimableAfter, 0, "claimable should be equal to 0 until checkpoint is called");

        _jumpOneEpoch();
        revenueHandler.checkpoint();

        claimableAfter = revenueHandler.claimable(tokenId, aura);

        revenueHandler.claim(tokenId, aura, address(0), claimableAfter, address(this));

        uint256 balAfter = IERC20(aura).balanceOf(address(this));

        assertEq(balAfter, claimableAfter, "should be equal to amount claimed");
    }

    function testClaimRevenueWithoutVoting() external {
        uint256 revAmt = 1000e18;
        uint256 tokenId1 = createVeAlcx(address(this), TOKEN_1, MAXTIME, false);
        uint256 tokenId2 = createVeAlcx(admin, TOKEN_1, MAXTIME, false);

        _accrueRevenueAndJumpOneEpoch(revAmt);

        voter.reset(tokenId1);

        _accrueRevenueAndJumpOneEpoch(revAmt);

        uint256 claimable1 = revenueHandler.claimable(tokenId1, alusd);
        uint256 claimable2 = revenueHandler.claimable(tokenId2, alusd);

        assertEq(claimable1, claimable2, "claimable amounts should be equal");
    }

    function testClaimRevenueMultipleEpochs() external {
        uint256 revAmt = 1000e18;
        uint256 tokenId = _setupClaimableRevenue(revAmt);

        _accrueRevenue(dai, revAmt);
        revenueHandler.checkpoint();

        _jumpOneEpoch();

        uint256 claimable = revenueHandler.claimable(tokenId, alusd);
        assertApproxEq(revAmt * 2, claimable, (revAmt * 2) / DELTA);

        uint256 debtAmt = 5000e18;
        _takeDebt(debtAmt);

        revenueHandler.claim(tokenId, alusd, address(alusdAlchemist), claimable, address(this));
        (int256 finalDebt, ) = alusdAlchemist.accounts(address(this));
        assertApproxEq(debtAmt - claimable, uint256(finalDebt), uint256(finalDebt) / DELTA);
    }

    function testClaimPartialRevenue() external {
        uint256 revAmt = 1000e18;
        uint256 tokenId = _setupClaimableRevenue(revAmt);

        uint256 claimAmt = 200e18;

        uint256 debtAmt = 5000e18;
        _takeDebt(debtAmt);

        revenueHandler.claim(tokenId, alusd, address(alusdAlchemist), claimAmt, address(this));
        (int256 currentDebt, ) = alusdAlchemist.accounts(address(this));
        assertApproxEq(debtAmt - (claimAmt), uint256(currentDebt), uint256(currentDebt) / DELTA);

        revenueHandler.claim(tokenId, alusd, address(alusdAlchemist), claimAmt, address(this));
        (int256 finalDebt, ) = alusdAlchemist.accounts(address(this));
        assertApproxEq(debtAmt - (2 * claimAmt), uint256(finalDebt), uint256(finalDebt) / DELTA);
    }

    function testClaimTooMuch() external {
        uint256 revAmt = 1000e18;
        uint256 tokenId = _setupClaimableRevenue(revAmt);

        uint256 claimable = revenueHandler.claimable(tokenId, alusd);

        uint256 debtAmt = 5000e18;
        _takeDebt(debtAmt);

        revenueHandler.claim(tokenId, alusd, address(alusdAlchemist), claimable / 2, address(this));

        expectError("Not enough claimable");
        revenueHandler.claim(tokenId, alusd, address(alusdAlchemist), claimable, address(this));

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
        revenueHandler.claim(tokenId, alusd, address(alusdAlchemist), claimable, address(this));
        uint256 balAfter = IERC20(alusd).balanceOf(address(this));

        uint256 bal = balAfter - balBefore;

        assertApproxEq(debtAmt, bal, bal / DELTA);
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
        assertApproxEq(claimable, revAmt, revAmt / DELTA);
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
        assertApproxEq(claimable, revAmt, revAmt / DELTA);

        revenueHandler.claim(tokenId, alusd, address(alusdAlchemist), claimable, address(this));

        claimable = revenueHandler.claimable(tokenId, alusd);
        assertEq(claimable, 0);

        // checkpoint the accrued revenue
        revenueHandler.checkpoint();
        claimable = revenueHandler.claimable(tokenId, alusd);
        assertApproxEq(claimable, revAmt, revAmt / DELTA);
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
        veALCX.depositFor(tokenId, lockAmt);

        _accrueRevenueAndJumpOneEpoch(revAmt); // this revenue SHOULD be claimable

        uint256 claimable = revenueHandler.claimable(tokenId, alusd);
        assertApproxEq(claimable, 2 * revAmt, (2 * revAmt) / DELTA);
    }

    function testCheckpointETH() external {
        address[] memory alethCrvTokenIds = new address[](2);
        alethCrvTokenIds[0] = address(weth); // eth
        alethCrvTokenIds[1] = aleth;

        CurveEthPoolAdapter alethCpa = new CurveEthPoolAdapter(alethcrv, alethCrvTokenIds, address(weth));

        revenueHandler.addRevenueToken(address(weth));
        revenueHandler.setDebtToken(address(weth), aleth);
        revenueHandler.setPoolAdapter(address(weth), address(alethCpa));

        uint256 revAmt = 10e18;
        _accrueRevenue(address(weth), revAmt);

        uint256 balBefore = IERC20(aleth).balanceOf(address(revenueHandler));
        assertEq(balBefore, 0);
        revenueHandler.checkpoint();
        uint256 balAfter = IERC20(aleth).balanceOf(address(revenueHandler));
        assertApproxEq(revAmt, balAfter, revAmt / 30);
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
        revenueHandler.claim(tokenId, alusd, address(alusdAlchemist), claimable, address(this));

        _accrueRevenueAndJumpOneEpoch(revAmt);
        uint256 holderClaimable = revenueHandler.claimable(holderTokenId, alusd);
        assertApproxEq(holderClaimable, (2 * revAmt * 4) / 5, ((2 * revAmt * 4) / 5) / DELTA);

        hevm.startPrank(holder);
        revenueHandler.claim(holderTokenId, alusd, address(alusdAlchemist), holderClaimable, holder);
        hevm.stopPrank();

        claimable = revenueHandler.claimable(tokenId, alusd);
        revenueHandler.claim(tokenId, alusd, address(alusdAlchemist), claimable, address(this));

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

    function testTreasuryRevenue() external {
        uint256 treasuryPct = 5000; // 50%

        revenueHandler.setTreasuryPct(treasuryPct);

        uint256 revAmt = 1000e18;
        _accrueRevenue(dai, revAmt);

        uint256 usdcRevAmt = 1000e6;
        _accrueRevenue(usdc, usdcRevAmt);

        uint256 tBalBeforeDai = IERC20(dai).balanceOf(address(admin));
        uint256 tBalBeforeUsdc = IERC20(usdc).balanceOf(address(admin));
        uint256 balBefore = IERC20(alusd).balanceOf(address(revenueHandler));
        assertEq(balBefore, 0);
        revenueHandler.checkpoint();
        uint256 tBalAfterDai = IERC20(dai).balanceOf(address(admin));
        uint256 tBalAfterUsdc = IERC20(usdc).balanceOf(address(admin));
        uint256 balAfter = IERC20(alusd).balanceOf(address(revenueHandler));
        assertApproxEq(1000e18, balAfter, 2000e18 / uint256(DELTA));
        assertEq(revAmt / 2, tBalAfterDai - tBalBeforeDai);
        assertEq(usdcRevAmt / 2, tBalAfterUsdc - tBalBeforeUsdc);
    }

    function testSetTreasuryPct(uint256 newPct) external {
        if (newPct == revenueHandler.treasuryPct()) {
            hevm.expectRevert(abi.encodePacked("treasury pct unchanged"));
            revenueHandler.setTreasuryPct(newPct);
        } else if (newPct > BPS) {
            hevm.expectRevert(abi.encodePacked("treasury pct too large"));
            revenueHandler.setTreasuryPct(newPct);
        } else {
            revenueHandler.setTreasuryPct(newPct);
            assertEq(revenueHandler.treasuryPct(), newPct);
        }
    }

    function testEnableRevenueToken() external {
        address revenueToken = revenueHandler.revenueTokens(0);

        hevm.expectRevert(abi.encodePacked("Token enabled"));
        revenueHandler.enableRevenueToken(revenueToken);

        revenueHandler.disableRevenueToken(revenueToken);

        hevm.expectRevert(abi.encodePacked("Token disabled"));
        revenueHandler.disableRevenueToken(revenueToken);

        revenueHandler.enableRevenueToken(revenueToken);
    }

    function testSetTreasury() external {
        hevm.expectRevert(abi.encodePacked("treasury cannot be 0x0"));
        revenueHandler.setTreasury(address(0));

        revenueHandler.setTreasury(admin);
        assertEq(revenueHandler.treasury(), admin, "treasury should be admin");
    }
}
