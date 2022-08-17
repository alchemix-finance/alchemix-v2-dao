// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./BaseTest.sol";
import "forge-std/console2.sol";

contract VotingTest is BaseTest {
    VotingEscrow veALCX;
    Voter voter;
    PairFactory pairFactory;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    RewardsDistributor distributor;
    Minter minter;

    uint256 depositAmount = 999 ether;
    uint256 lockTime = 30 days;

    function setUp() public {
        veALCX = new VotingEscrow(address(alcx));
        pairFactory = new PairFactory();
        gaugeFactory = new GaugeFactory(address(pairFactory));
        bribeFactory = new BribeFactory();
        voter = new Voter(address(veALCX), address(gaugeFactory), address(bribeFactory));

        address[] memory tokens = new address[](1);
        tokens[0] = address(alcx);
        voter.initialize(tokens, address(admin));

        alcx.approve(address(veALCX), 1e18);
        veALCX.createLock(1e18, 4 * 365 * 86400);
        distributor = new RewardsDistributor(address(veALCX));
        veALCX.setVoter(address(voter));

        InitializationParams memory params = InitializationParams(
            address(voter),
            address(veALCX),
            address(distributor),
            1793678e18,
            12724e18,
            130e18
        );

        minter = new Minter(params);

        distributor.setDepositor(address(minter));

        // // Create veNFT for `account`
        // hevm.startPrank(account);
        // assertGt(alcx.balanceOf(account), depositAmount, "Not enough alcx");

        // alcx.approve(address(veALCX), depositAmount);
        // uint256 tokenId = veALCX.createLock(depositAmount, lockTime);

        // // Check that veNFT was created
        // address owner = veALCX.ownerOf(tokenId);
        // assertEq(owner, account);

        // // Check veNFT parameters
        // (int128 amount, uint256 end) = veALCX.locked(tokenId);
        // hevm.stopPrank();
    }

    // /// @dev Vote on a gauge using the veNFT
    // function testVote() public {}
}
