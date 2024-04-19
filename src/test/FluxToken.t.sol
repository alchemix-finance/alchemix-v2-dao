// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract FluxTokenTest is BaseTest {
    function setUp() public {
        setupContracts(block.timestamp);
    }

    function testAdminFunctionErrors() external {
        address admin = flux.admin();

        hevm.expectRevert(abi.encodePacked("not admin"));
        flux.setAdmin(devmsig);

        hevm.prank(admin);
        hevm.expectRevert(abi.encodePacked("not pending admin"));
        flux.acceptAdmin();

        hevm.expectRevert(abi.encodePacked("not admin"));
        flux.setVoter(devmsig);

        hevm.expectRevert(abi.encodePacked("not admin"));
        flux.setVeALCX(devmsig);

        hevm.expectRevert(abi.encodePacked("not admin"));
        flux.setAlchemechNFT(devmsig);

        hevm.expectRevert(abi.encodePacked("not admin"));
        flux.setPatronNFT(devmsig);

        hevm.expectRevert(abi.encodePacked("not admin"));
        flux.setNftMultiplier(1);

        hevm.expectRevert(abi.encodePacked("not admin"));
        flux.setBptMultiplier(1);
    }

    function testUpdateToZero() external {
        address admin = flux.admin();
        address minter = flux.minter();

        hevm.prank(admin);
        flux.setAdmin(devmsig);

        hevm.startPrank(devmsig);
        flux.acceptAdmin();

        hevm.expectRevert(abi.encodePacked("FluxToken: voter cannot be zero address"));
        flux.setVoter(address(0));

        hevm.expectRevert(abi.encodePacked("FluxToken: veALCX cannot be zero address"));
        flux.setVeALCX(address(0));

        hevm.expectRevert(abi.encodePacked("FluxToken: alchemechNFT cannot be zero address"));
        flux.setAlchemechNFT(address(0));

        hevm.expectRevert(abi.encodePacked("FluxToken: patronNFT cannot be zero address"));
        flux.setPatronNFT(address(0));

        hevm.expectRevert(abi.encodePacked("FluxToken: nftMultiplier cannot be zero"));
        flux.setNftMultiplier(0);

        hevm.expectRevert(abi.encodePacked("FluxToken: bptMultiplier cannot be zero"));
        flux.setBptMultiplier(0);

        hevm.stopPrank();

        hevm.prank(minter);
        hevm.expectRevert(abi.encodePacked("FluxToken: minter cannot be zero address"));
        flux.setMinter(address(0));
    }

    function testSetMultipliersLimit() external {
        hevm.startPrank(admin);

        hevm.expectRevert(abi.encodePacked("FluxToken: nftMultiplier cannot be greater than BPS"));
        flux.setNftMultiplier(BPS + 1);

        hevm.expectRevert(abi.encodePacked("FluxToken: bptMultiplier cannot be greater than BPS"));
        flux.setBptMultiplier(BPS + 1);
    }

    function testMintFluxFromNFT() external {
        uint256 tokenId = 4;
        address ownerOfPatronNFT = IAlEthNFT(patronNFT).ownerOf(tokenId);
        address ownerOfAlchemechNFT = IAlchemechNFT(alchemechNFT).ownerOf(tokenId);

        assertEq(flux.balanceOf(ownerOfPatronNFT), 0, "owner should have no flux");
        assertEq(flux.balanceOf(ownerOfAlchemechNFT), 0, "owner should have no flux");

        uint256 tokenData1 = IAlEthNFT(patronNFT).tokenData(tokenId);
        uint256 patronTotal = flux.getClaimableFlux(tokenData1, patronNFT);

        uint256 tokenData2 = IAlchemechNFT(alchemechNFT).tokenData(tokenId);
        uint256 alchemechTotal = flux.getClaimableFlux(tokenData2, alchemechNFT);
        // Get value of alchemech without multiplier
        uint256 alchemechTotalNoMultiplier = flux.getClaimableFlux(tokenData2, patronNFT);

        assertGt(alchemechTotalNoMultiplier, alchemechTotal, "non multiplier calc should be higher");

        hevm.prank(ownerOfPatronNFT);
        flux.nftClaim(patronNFT, tokenId);

        hevm.prank(ownerOfAlchemechNFT);
        flux.nftClaim(alchemechNFT, tokenId);

        assertEq(flux.balanceOf(ownerOfPatronNFT), patronTotal, "owner should have patron flux");
        assertEq(flux.balanceOf(ownerOfAlchemechNFT), alchemechTotal, "owner should have alchemech flux");
    }

    function testCalculateBPT() external {
        uint256 amount = 1000;
        uint256 bptCalculation = flux.calculateBPT(amount);

        assertEq(amount * flux.bptMultiplier(), bptCalculation, "should calculate BPT correctly");
    }

    function testMintFluxFromNFTErrors() external {
        uint256 tokenId = 4;
        address ownerOfPatronNFT = IAlEthNFT(patronNFT).ownerOf(tokenId);
        address ownerOfAlchemechNFT = IAlchemechNFT(alchemechNFT).ownerOf(tokenId);

        hevm.expectRevert(abi.encodePacked("invalid NFT"));
        hevm.prank(ownerOfPatronNFT);
        flux.nftClaim(address(0), tokenId);

        hevm.expectRevert(abi.encodePacked("not owner of Patron NFT"));
        hevm.prank(ownerOfAlchemechNFT);
        flux.nftClaim(patronNFT, tokenId);

        hevm.expectRevert(abi.encodePacked("not owner of Alchemech NFT"));
        hevm.prank(ownerOfPatronNFT);
        flux.nftClaim(alchemechNFT, tokenId);

        // Attempt to claim twice
        hevm.startPrank(ownerOfPatronNFT);
        flux.nftClaim(patronNFT, tokenId);

        hevm.expectRevert(abi.encodePacked("already claimed"));
        flux.nftClaim(patronNFT, tokenId);
        hevm.stopPrank();

        // Attempt to claim after claim period (1 year)
        hevm.warp(block.timestamp + 366 days);
        hevm.expectRevert(abi.encodePacked("claim period has passed"));
        flux.nftClaim(patronNFT, tokenId);
    }

    function testFluxAccrual() external {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, veALCX.MAXTIME(), false);

        uint256 balanceOfToken = veALCX.balanceOfToken(tokenId);
        console2.log("votingPower       :", balanceOfToken);

        uint256 maxVotingPower = voter.maxVotingPower(tokenId);
        console2.log("maxVotingPower    :", maxVotingPower);

        uint256 oneEpochFlux = veALCX.claimableFlux(tokenId);
        console2.log("oneEpochFlux      :", oneEpochFlux);

        uint256 fluxOver4Years = veALCX.amountToRagequit(tokenId);
        console2.log("fluxOver4Years    :", fluxOver4Years);
    }

    // veALCX should earn enough flux over <fluxMultiplier> years to ragequit
    function testTotalFluxAccrual() external {
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, veALCX.MAXTIME(), true);

        uint256 amountToRagequit = veALCX.amountToRagequit(tokenId);

        uint256 totalEpochsToRagequit = veALCX.fluxMultiplier() * ((MAXTIME) / veALCX.EPOCH());

        uint256 unclaimedFluxStart = flux.getUnclaimedFlux(tokenId);
        assertEq(unclaimedFluxStart, 0, "should start with no unclaimed flux");

        // Mock 4 years of epochs
        for (uint256 i = 0; i < totalEpochsToRagequit; i++) {
            hevm.prank(admin);
            voter.reset(tokenId);

            hevm.warp(newEpoch());
            voter.distribute();
        }

        uint256 unclaimedFluxEnd = flux.getUnclaimedFlux(tokenId);

        assertEq(unclaimedFluxEnd, amountToRagequit, "should have all unclaimed flux");
    }

    function testFluxActions() external {
        address bribeAddress = voter.bribes(address(sushiGauge));

        uint256 tokenId1 = createVeAlcx(admin, TOKEN_1, veALCX.MAXTIME(), false);
        uint256 tokenId2 = createVeAlcx(beef, TOKEN_1, veALCX.MAXTIME(), false);

        uint256 amount1 = veALCX.claimableFlux(tokenId1);
        uint256 amount2 = veALCX.claimableFlux(tokenId2);

        uint256 totalAmount = amount1 + amount2;

        uint256 unclaimedFlux1Start = flux.getUnclaimedFlux(tokenId1);
        uint256 unclaimedFlux2Start = flux.getUnclaimedFlux(tokenId2);

        assertEq(unclaimedFlux1Start, 0, "should start with no unclaimed flux");
        assertEq(unclaimedFlux2Start, 0, "should start with no unclaimed flux");

        address[] memory pools = new address[](1);
        pools[0] = sushiPoolAddress;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 5000;

        address[] memory bribes = new address[](1);
        bribes[0] = address(bribeAddress);
        address[][] memory tokens = new address[][](2);
        tokens[0] = new address[](1);
        tokens[0][0] = bal;

        hevm.prank(admin);
        voter.vote(tokenId1, pools, weights, 0);

        hevm.prank(beef);
        voter.vote(tokenId2, pools, weights, 0);

        // Fast forward epochs
        hevm.warp(newEpoch());

        voter.distribute();

        hevm.expectRevert(abi.encodePacked("not voter"));
        flux.updateFlux(tokenId1, amount1);

        hevm.expectRevert(abi.encodePacked("not voter"));
        flux.accrueFlux(tokenId1);

        hevm.prank(address(voter));
        hevm.expectRevert(abi.encodePacked("not enough flux"));
        flux.updateFlux(tokenId1, TOKEN_100K);

        hevm.expectRevert(abi.encodePacked("not veALCX"));
        flux.mergeFlux(tokenId1, tokenId2);

        hevm.prank(address(veALCX));
        flux.mergeFlux(tokenId1, tokenId2);

        uint256 unclaimedFlux1End = flux.getUnclaimedFlux(tokenId1);
        uint256 unclaimedFlux2End = flux.getUnclaimedFlux(tokenId2);

        assertEq(unclaimedFlux1End, 0, "should have no unclaimed flux");
        assertEq(unclaimedFlux2End, totalAmount, "should have all unclaimed flux");
    }
}
