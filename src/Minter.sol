// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "./libraries/Math.sol";
import "./interfaces/IRewardsDistributor.sol";
import "./interfaces/IVelo.sol";
import "./interfaces/IVoter.sol";
import "./interfaces/IVotingEscrow.sol";

// codifies the minting rules as per ve(3,3), abstracted from the token to support any token that allows minting
// TODO: decide on whether to abstract from VELO or not. currently it's only somewhat abstracted (e.g. L38)

contract Minter {
    // TODO
    // update these vars and logic to match ALCX emissinos curve
    // need to add logic that brings current emission down every period
    // levels out at tail emission rate
    uint256 internal constant WEEK = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint256 internal constant EMISSION = 990;
    uint256 internal constant TAIL_EMISSION = 2;
    uint256 internal constant PRECISION = 1000;
    // TODO
    // IgALCX
    IVelo public immutable _velo;
    IVoter public immutable _voter;
    IVotingEscrow public immutable _ve;
    IRewardsDistributor public immutable _rewards_distributor;
    uint256 public weekly = 15000000e18;
    uint256 public active_period;
    uint256 internal constant LOCK = 86400 * 7 * 52 * 4;

    address internal initializer;
    address public admin;
    address public pendingAdmin;
    uint256 public adminRate;
    uint256 public constant MAX_ADMIN_RATE = 50; // 50 bps = 0.05%

    event Mint(
        address indexed sender,
        uint256 weekly,
        uint256 circulating_supply,
        uint256 circulating_emission
    );

    constructor(
        address __voter, // the voting & distribution system
        address __ve, // the ve(3,3) system that will be locked into
        address __rewards_distributor // the distribution system that ensures users aren't diluted
    ) {
        initializer = msg.sender;
        admin = msg.sender;
        adminRate = 30; // 30 bps = 0.03%
        _velo = IVelo(IVotingEscrow(__ve).token());
        _voter = IVoter(__voter);
        _ve = IVotingEscrow(__ve);
        _rewards_distributor = IRewardsDistributor(__rewards_distributor);
        active_period = ((block.timestamp + (2 * WEEK)) / WEEK) * WEEK;
    }

    function initialize(
        address[] memory claimants,
        uint256[] memory amounts,
        uint256 max // sum amounts / max = % ownership of top protocols, so if initial 20m is distributed, and target is 25% protocol ownership, then max - 4 x 20m = 80m
    ) external {
        require(initializer == msg.sender);
        // TODO
        // this looks velo-specific
        // i don't think we want to mint a bunch of ALCX out of the gate.
        _velo.mint(address(this), max);
        _velo.approve(address(_ve), type(uint256).max);
        for (uint256 i = 0; i < claimants.length; i++) {
            _ve.create_lock_for(amounts[i], LOCK, claimants[i]);
        }
        initializer = address(0);
        active_period = ((block.timestamp + WEEK) / WEEK) * WEEK;
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "not admin");
        pendingAdmin = _admin;
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "not pending admin");
        admin = pendingAdmin;
    }

    function setAdminRate(uint256 _adminRate) external {
        require(msg.sender == admin, "not admin");
        require(_adminRate <= MAX_ADMIN_RATE, "rate too high");
        adminRate = _adminRate;
    }

    // calculate circulating supply as total token supply - locked supply
    function circulating_supply() public view returns (uint256) {
        return _velo.totalSupply() - _ve.totalSupply();
    }

    // emission calculation is 2% of available supply to mint adjusted by circulating / total supply
    function calculate_emission() public view returns (uint256) {
        return
            (weekly * EMISSION * circulating_supply()) /
            PRECISION /
            _velo.totalSupply();
    }

    // weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
    function weekly_emission() public view returns (uint256) {
        return Math.max(calculate_emission(), circulating_emission());
    }

    // calculates tail end (infinity) emissions as 0.2% of total supply
    function circulating_emission() public view returns (uint256) {
        return (circulating_supply() * TAIL_EMISSION) / PRECISION;
    }

    // calculate inflation and adjust ve balances accordingly
    function calculate_growth(uint256 _minted) public view returns (uint256) {
        uint256 _veTotal = _ve.totalSupply();
        uint256 _veloTotal = _velo.totalSupply();
        return
            (((((_minted * _veTotal) / _veloTotal) * _veTotal) / _veloTotal) *
                _veTotal) /
            _veloTotal /
            2;
    }

    // update period can only be called once per cycle (1 week)
    function update_period() external returns (uint256) {
        uint256 _period = active_period;
        if (block.timestamp >= _period + WEEK && initializer == address(0)) {
            // only trigger if new week
            _period = (block.timestamp / WEEK) * WEEK;
            active_period = _period;
            weekly = weekly_emission();

            uint256 _growth = calculate_growth(weekly);
            uint256 _adminEmissions = (adminRate * (_growth + weekly)) /
                (PRECISION - adminRate);
            uint256 _required = _growth + weekly + _adminEmissions;
            uint256 _balanceOf = _velo.balanceOf(address(this));
            if (_balanceOf < _required) {
                _velo.mint(address(this), _required - _balanceOf);
            }

            require(_velo.transfer(admin, _adminEmissions));
            require(_velo.transfer(address(_rewards_distributor), _growth));
            _rewards_distributor.checkpoint_token(); // checkpoint token balance that was just minted in rewards distributor
            _rewards_distributor.checkpoint_total_supply(); // checkpoint supply

            _velo.approve(address(_voter), weekly);
            _voter.notifyRewardAmount(weekly);

            emit Mint(
                msg.sender,
                weekly,
                circulating_supply(),
                circulating_emission()
            );
        }
        return _period;
    }
}
