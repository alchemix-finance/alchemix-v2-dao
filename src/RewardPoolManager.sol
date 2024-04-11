// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "src/interfaces/IRewardPoolManager.sol";
import "src/interfaces/aura/IRewardPool4626.sol";
import "src/interfaces/aura/IRewardStaking.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract RewardPoolManager is IRewardPoolManager {
    using SafeERC20 for IERC20;

    uint256 internal constant MAX_REWARD_POOL_TOKENS = 10;
    // please complete these state variable descriptions and format them for docs
    address public admin;
    address public pendingAdmin;
    address public veALCX;
    address public rewardPool; // destination for poolToken
    address public treasury;
    address public poolToken; // BPT

    address[] public rewardPoolTokens;

    mapping(address => bool) public isRewardPoolToken;

    constructor(address _admin, address _veALCX, address _poolToken, address _rewardPool, address _treasury) {
        admin = _admin;
        veALCX = _veALCX;
        poolToken = _poolToken;
        rewardPool = _rewardPool;
        treasury = _treasury;
    }

    /// @inheritdoc IRewardPoolManager
    function setAdmin(address _admin) external {
        require(msg.sender == admin, "not admin");
        pendingAdmin = _admin;
    }

    /// @inheritdoc IRewardPoolManager
    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "not pending admin");
        admin = pendingAdmin;
        emit AdminUpdated(pendingAdmin);
    }

    /// @inheritdoc IRewardPoolManager
    function setTreasury(address _treasury) external {
        require(msg.sender == admin, "not admin");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    /// @inheritdoc IRewardPoolManager
    function setRewardPool(address _rewardPool) external {
        require(msg.sender == admin, "not admin");
        rewardPool = _rewardPool;
        emit RewardPoolUpdated(_rewardPool);
    }

    /// @inheritdoc IRewardPoolManager
    function setPoolToken(address _poolToken) external {
        require(msg.sender == admin, "not admin");
        poolToken = _poolToken;
        emit PoolTokenUpdated(_poolToken);
    }

    /// @inheritdoc IRewardPoolManager
    function setVeALCX(address _veALCX) external {
        require(msg.sender == admin, "not admin");
        veALCX = _veALCX;
        emit VeALCXUpdated(_veALCX);
    }

    /// @inheritdoc IRewardPoolManager
    function depositIntoRewardPool(uint256 _amount) external returns (bool) {
        require(msg.sender == veALCX, "must be veALCX");

        IERC20(poolToken).approve(rewardPool, _amount);
        IRewardPool4626(rewardPool).deposit(_amount, address(this));
        return true;
    }

    /// @inheritdoc IRewardPoolManager
    function withdrawFromRewardPool(uint256 _amount) external returns (bool) {
        require(msg.sender == veALCX, "must be veALCX");

        IRewardPool4626(rewardPool).withdraw(_amount, veALCX, address(this));
        return true;
    }

    /// @inheritdoc IRewardPoolManager
    function claimRewardPoolRewards() external {
        require(msg.sender == admin, "not admin");
        IRewardStaking(rewardPool).getReward(address(this), false);
        uint256[] memory rewardPoolAmounts = new uint256[](rewardPoolTokens.length);
        for (uint256 i = 0; i < rewardPoolTokens.length; i++) {
            rewardPoolAmounts[i] = IERC20(rewardPoolTokens[i]).balanceOf(address(this));
            if (rewardPoolAmounts[i] > 0) {
                IERC20(rewardPoolTokens[i]).safeTransfer(treasury, rewardPoolAmounts[i]);
                emit ClaimRewardPoolRewards(msg.sender, rewardPoolTokens[i], rewardPoolAmounts[i]);
            }
        }
    }

    /// @inheritdoc IRewardPoolManager
    function addRewardPoolToken(address _token) external {
        require(msg.sender == admin, "not admin");
        _addRewardPoolToken(_token);
    }

    /// @inheritdoc IRewardPoolManager
    function addRewardPoolTokens(address[] calldata _tokens) external {
        require(msg.sender == admin, "not admin");
        for (uint256 i = 0; i < _tokens.length; i++) {
            _addRewardPoolToken(_tokens[i]);
        }
    }

    /// @inheritdoc IRewardPoolManager
    function swapOutRewardPoolToken(uint256 i, address oldToken, address newToken) external {
        require(msg.sender == admin, "not admin");
        require(rewardPoolTokens[i] == oldToken, "incorrect token");
        require(newToken != address(0));

        isRewardPoolToken[oldToken] = false;
        isRewardPoolToken[newToken] = true;
        rewardPoolTokens[i] = newToken;
    }

    /*
        Internal functions
    */

    function _addRewardPoolToken(address token) internal {
        if (!isRewardPoolToken[token] && token != address(0)) {
            require(rewardPoolTokens.length < MAX_REWARD_POOL_TOKENS, "too many reward pool tokens");

            isRewardPoolToken[token] = true;
            rewardPoolTokens.push(token);
        }
    }
}
