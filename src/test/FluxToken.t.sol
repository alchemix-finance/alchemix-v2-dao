// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "./BaseTest.sol";

contract FluxTokenTest is BaseTest {
    function setUp() public {
        setupContracts(block.timestamp);
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
        uint256 tokenId = createVeAlcx(admin, TOKEN_1, veALCX.EPOCH(), false);

        uint256 balanceOfToken = veALCX.balanceOfToken(tokenId);
        console2.log("votingPower       :", balanceOfToken);

        uint256 maxVotingPower = voter.maxVotingPower(tokenId);
        console2.log("maxVotingPower    :", maxVotingPower);

        uint256 oneEpochFlux = veALCX.claimableFlux(tokenId);
        console2.log("oneEpochFlux      :", oneEpochFlux);

        uint256 fluxOver4Years = veALCX.amountToRagequit(tokenId);
        console2.log("fluxOver4Years    :", fluxOver4Years);
    }
}
