// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "src/libraries/Math.sol";
import "src/interfaces/IBribe.sol";
import "src/interfaces/IGaugeFactory.sol";
import "src/interfaces/IBaseGauge.sol";
import "src/interfaces/IVoter.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title  Base Gauge
 * @notice Implementation of functionality that various gauge types use or extend
 * @notice Gauges are used to incentivize pools, they emit or passthrough reward tokens
 */
abstract contract BaseGauge is IBaseGauge {
    uint256 internal constant DURATION = 5 days; // Rewards released over voting period
    uint256 internal constant BRIBE_LAG = 1 days;
    uint256 internal constant MAX_REWARD_TOKENS = 16;

    address public ve; // Ve token used for gauges
    address public bribe;
    address public voter;
    address public admin;
    address public pendingAdmin;
    address public receiver;
    address public rewardToken;

    // Re-entrancy check
    uint256 internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    /*
        View functions
    */

    function getVotingStage(uint256 timestamp) public pure returns (VotingStage) {
        uint256 modTime = timestamp % (7 days);
        if (modTime < BRIBE_LAG) {
            return VotingStage.BribesPhase;
        } else if (modTime > (BRIBE_LAG + DURATION)) {
            return VotingStage.RewardsPhase;
        }
        return VotingStage.VotesPhase;
    }

    /*
        External functions
    */

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "not admin");
        pendingAdmin = _admin;
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "not pending admin");
        admin = pendingAdmin;
    }

    function updateReceiver(address _receiver) external {
        require(msg.sender == admin, "not admin");
        receiver = _receiver;
    }

    /// @inheritdoc IBaseGauge
    function notifyRewardAmount(address _token, uint256 _amount) external lock {
        require(msg.sender == voter, "not voter");
        require(_amount > 0, "zero amount");
        _safeTransferFrom(_token, msg.sender, address(this), _amount);

        emit NotifyReward(msg.sender, _token, _amount);

        _passthroughRewards(_amount);
    }

    /*
        Internal functions
    */

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeApprove(address token, address spender, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, spender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    /**
     * @notice Override function to implement passthrough logic
     * @param _amount Amount of rewards
     */
    function _passthroughRewards(uint256 _amount) internal virtual {}
}
