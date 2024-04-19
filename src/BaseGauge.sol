// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "src/libraries/Math.sol";
import "src/interfaces/IBribe.sol";
import "src/interfaces/IBaseGauge.sol";
import "src/interfaces/IVoter.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title  Base Gauge
 * @notice Implementation of functionality that various gauge types use or extend
 * @notice Gauges are used to incentivize pools, they emit or passthrough reward tokens
 */
abstract contract BaseGauge is IBaseGauge {
    using SafeERC20 for IERC20;

    /// @notice Rewards released over voting period
    uint256 internal constant DURATION = 2 weeks;
    uint256 internal constant BRIBE_LAG = 1 days;
    uint256 internal constant MAX_REWARD_TOKENS = 16;

    /// @notice veALCX token used for gauges
    address public ve;
    /// @notice Address of bribe contract
    address public bribe;
    /// @notice Address of voter contract
    address public voter;
    /// @notice Address of admin
    address public admin;
    /// @notice Address of pending admin
    address public pendingAdmin;
    /// @notice Address that receives the ALCX rewards
    address public receiver;
    /// @notice Address of the reward token
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

    /// @inheritdoc IBaseGauge
    function updateReceiver(address _receiver) external {
        require(msg.sender == admin, "not admin");
        require(_receiver != address(0), "cannot be zero address");
        require(_receiver != receiver, "same receiver");
        receiver = _receiver;
    }

    /// @inheritdoc IBaseGauge
    function notifyRewardAmount(uint256 _amount) external lock {
        require(msg.sender == voter, "not voter");
        require(_amount > 0, "zero amount");
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);

        emit NotifyReward(msg.sender, rewardToken, _amount);

        _passthroughRewards(_amount);
    }

    /*
        Internal functions
    */

    /**
     * @notice Override function to implement passthrough logic
     * @param _amount Amount of rewards
     */
    function _passthroughRewards(uint256 _amount) internal virtual {}
}
