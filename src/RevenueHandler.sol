// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "./interfaces/IRevenueHandler.sol";
import "./interfaces/IPoolAdapter.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/v2-foundry/src/interfaces/IAlchemistV2.sol";
import "../lib/v2-foundry/src/base/ErrorMessages.sol";
import "./interfaces/IVotingEscrow.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract RevenueHandler is IRevenueHandler, Ownable {
    using SafeERC20 for IERC20;
    /// @notice Parameters to define actions with respect to melting a revenue token for alchemic-tokens.
    struct RevenueTokenConfig {
        /// The target alchemic-token.
        address debtToken;
        /// A IPoolAdapter that can be used to trade revenue token for `debtToken`.
        address poolAdapter;
    }

    /// @notice A checkpoint on the state of a user's account for a given debtToken
    struct Claimable {
        /// An amount of the target debtToken that the user can currently claim (leftover from an incomplete claim).
        uint256 unclaimed;
        /// The last epoch that the user claimed the target debtToken.
        uint256 lastClaimEpoch;
    }

    address public veALCX;
    address[] public debtTokens;
    address[] public revenueTokens;
    mapping(address /* token */ => RevenueTokenConfig) public revenueTokenConfigs;
    mapping(uint256 /* epoch */ => mapping(address /* debtToken */ => uint256 /* epoch revenue */)) public epochRevenues;
    mapping(uint256 /* tokenId */ => mapping(address /* debtToken */ => Claimable)) public userCheckpoints;
    uint256 public currentEpoch;

    constructor(address _veALCX) Ownable() {
        veALCX = _veALCX;
    }

    /*
        View functions
    */

    /// @inheritdoc IRevenueHandler
    function claimable(uint256 tokenId, address debtToken) external view override returns (uint256) {
        return _claimable(tokenId, debtToken);
    }

    /*
        Admin functions
    */

    /// @inheritdoc IRevenueHandler
    function addDebtToken(address debtToken) external override onlyOwner {
        for (uint256 i = 0; i < debtTokens.length; i++) {
            if (debtTokens[i] == debtToken) {
                revert("debt token already exists");
            }
        }
        debtTokens.push(debtToken);
    }

    /// @inheritdoc IRevenueHandler
    function removeDebtToken(address debtToken) external override onlyOwner {
        for (uint256 i = 0; i < debtTokens.length; i++) {
            if (debtTokens[i] == debtToken) {
                debtTokens[i] = debtTokens[debtTokens.length - 1];
                debtTokens.pop();
                return;
            }
        }
        revert("debt token does not exist");
    }

    /// @inheritdoc IRevenueHandler
    function setDebtToken(address revenueToken, address debtToken) external override onlyOwner {
        revenueTokenConfigs[revenueToken].debtToken = debtToken;
        emit SetDebtToken(revenueToken, debtToken);
    }

    /// @inheritdoc IRevenueHandler
    function setPoolAdapter(address revenueToken, address poolAdapter) external override onlyOwner {
        revenueTokenConfigs[revenueToken].poolAdapter = poolAdapter;
        emit SetPoolAdapter(revenueToken, poolAdapter);
    }

    /*
        User functions
    */

    /// @inheritdoc IRevenueHandler
    function claim(uint256 tokenId, address alchemist, uint256 amount, address recipient) external override {
        require(IVotingEscrow(veALCX).isApprovedOrOwner(msg.sender, tokenId), "not approved or owner");

        address debtToken = IAlchemistV2(alchemist).debtToken();
        uint256 amountClaimable = _claimable(tokenId, debtToken);
        require(amount <= amountClaimable, "Not enough claimable");

        userCheckpoints[tokenId][debtToken].lastClaimEpoch = currentEpoch;
        userCheckpoints[tokenId][debtToken].unclaimed = amountClaimable - amount;

        // burn
        IERC20(debtToken).approve(alchemist, amount);
        uint256 amountBurned = IAlchemistV2(alchemist).burn(amount, recipient);

        // burn() will only burn up to total cdp debt
        // send the leftover directly to the user
        if (amountBurned < amount) {
            IERC20(debtToken).safeTransfer(recipient, amount - amountBurned);
        }
        emit ClaimRevenue(tokenId, debtToken, amount, recipient);
    }

    /// @inheritdoc IRevenueHandler
    function checkpoint() external {
        uint256 oneEpoch = IVotingEscrow(veALCX).EPOCH();
        // only run checkpoint() once per epoch
        // TODO: add a check that it gets run during the correct phase of an epoch?
        if (block.timestamp >= currentEpoch + oneEpoch /* && initializer == address(0) */) {
            currentEpoch = (block.timestamp / oneEpoch) * oneEpoch;

            for (uint256 i = 0; i < revenueTokens.length; i++) {
                uint256 amountReceived = _melt(revenueTokens[i]);
                epochRevenues[currentEpoch][revenueTokenConfigs[revenueTokens[i]].debtToken] = amountReceived;
            }
        }
    }

    /*
        Internal functions
    */

    function _melt(address revenueToken) internal returns (uint256) {
        RevenueTokenConfig storage tokenConfig = revenueTokenConfigs[revenueToken];
        address poolAdapter = tokenConfig.poolAdapter;
        uint256 revenueTokenBalance = IERC20(revenueToken).balanceOf(address(this));
        if (revenueTokenBalance == 0) {
            return 0;
        }
        IERC20(revenueToken).safeTransfer(poolAdapter, revenueTokenBalance);
        return IPoolAdapter(poolAdapter).melt(revenueToken, tokenConfig.debtToken, revenueTokenBalance, 0); // TODO: fix minimum amount out
    }

    function _claimable(uint256 tokenId, address debtToken) internal view returns (uint256) {
        uint256 totalClaimable = 0;
        uint256 lastClaimEpoch = userCheckpoints[tokenId][debtToken].lastClaimEpoch;
        uint256 oneEpoch = IVotingEscrow(veALCX).EPOCH();
        for (uint256 epoch = lastClaimEpoch; epoch < currentEpoch; epoch + oneEpoch) {
            uint256 epochRevenue = epochRevenues[epoch][debtToken];
            uint256 epochUserVeBalance = IVotingEscrow(veALCX).balanceOfTokenAt(tokenId, epoch);
            uint256 epochTotalVeSupply = IVotingEscrow(veALCX).totalSupplyAtT(epoch);
            totalClaimable += epochRevenue * epochUserVeBalance / epochTotalVeSupply;
        }
        return totalClaimable + userCheckpoints[tokenId][debtToken].unclaimed;
    }
}