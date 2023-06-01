// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "src/interfaces/IRevenueHandler.sol";
import "src/interfaces/IPoolAdapter.sol";
import "src/interfaces/IVotingEscrow.sol";
import "lib/v2-foundry/src/interfaces/IAlchemistV2.sol";
import "lib/v2-foundry/src/base/ErrorMessages.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

/// @title RevenueHandler
/*
    This contract is meant to receive all revenue from the Alchemix protocol, and allow
        veALCX stakers to claim it, primarily as a form of debt repayment.
    IPoolAdapter contracts are used to plug into various DEXes so that revenue tokens (dai, usdc, weth, etc)
        can be traded for alAssets (alUSD, alETH, etc).  Once per epoch (at the beginning of the epoch)
        the `checkpoint()` function needs to be called so that any revenue accrued since the last checkpoint
        can be melted into its relative alAsset.  After `checkpoint()` is called, the current epoch's revenue
        is available to be claimed by veALCX stakers (as long as they were staked before `checkpoint()` was
        called).
    veALCX stakers can claim some or all of their available revenue.  When a staker calls `claim()`, they
        choose an amount, target alchemist, and target recipient.  The RevenueHandler will `burn()` up to
        `amount` of the alAsset used by `alchemist` on `recipient`'s account.  Any leftover revenue that
        is not burned will be sent directly to `recipient.
*/

contract RevenueHandler is IRevenueHandler, Ownable {
    using SafeERC20 for IERC20;
    /// @notice Parameters to define actions with respect to melting a revenue token for alchemic-tokens.
    struct RevenueTokenConfig {
        /// The target alchemic-token.
        address debtToken;
        /// A IPoolAdapter that can be used to trade revenue token for `debtToken`.
        address poolAdapter;
        /// A flag to enable or disable the revenue token
        bool disabled;
    }

    /// @notice A checkpoint on the state of a user's account for a given debtToken
    struct Claimable {
        /// An amount of the target debtToken that the user can currently claim (leftover from an incomplete claim).
        uint256 unclaimed;
        /// The last epoch that the user claimed the target debtToken.
        uint256 lastClaimEpoch;
    }

    uint256 internal constant WEEK = 1 weeks;
    uint256 internal constant BPS = 10_000;

    address public veALCX;
    address[] public debtTokens;
    address[] public revenueTokens;
    mapping(address => RevenueTokenConfig) /* token */
        public revenueTokenConfigs;
    mapping(uint256 => mapping(address => uint256)) /* epoch */ /* debtToken */ /* epoch revenue */
        public epochRevenues;
    mapping(uint256 => mapping(address => Claimable)) /* tokenId */ /* debtToken */
        public userCheckpoints;
    uint256 public currentEpoch;
    address public treasury;
    uint256 public treasuryPct;

    constructor(address _veALCX, address _treasury, uint256 _treasuryPct) Ownable() {
        veALCX = _veALCX;
        require(_treasury != address(0), "treasury cannot be 0x0");
        treasury = _treasury;
        require(treasuryPct <= BPS, "treasury pct too large");
        treasuryPct = _treasuryPct;
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
        emit DebtTokenAdded(debtToken);
    }

    /// @inheritdoc IRevenueHandler
    function removeDebtToken(address debtToken) external override onlyOwner {
        for (uint256 i = 0; i < debtTokens.length; i++) {
            if (debtTokens[i] == debtToken) {
                debtTokens[i] = debtTokens[debtTokens.length - 1];
                debtTokens.pop();
                emit DebtTokenRemoved(debtToken);
                return;
            }
        }
        revert("debt token does not exist");
    }

    /// @inheritdoc IRevenueHandler
    function addRevenueToken(address revenueToken) external override onlyOwner {
        for (uint256 i = 0; i < revenueTokens.length; i++) {
            if (revenueTokens[i] == revenueToken) {
                revert("revenue token already exists");
            }
        }
        revenueTokens.push(revenueToken);
        emit RevenueTokenTokenAdded(revenueToken);

    }

    /// @inheritdoc IRevenueHandler
    function removeRevenueToken(address revenueToken) external override onlyOwner {
        for (uint256 i = 0; i < revenueTokens.length; i++) {
            if (revenueTokens[i] == revenueToken) {
                revenueTokens[i] = revenueTokens[revenueTokens.length - 1];
                revenueTokens.pop();
                emit RevenueTokenTokenRemoved(revenueToken);
                return;
            }
        }
        revert("revenue token does not exist");
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

    /// @inheritdoc IRevenueHandler
    function disableRevenueToken(address revenueToken) external override onlyOwner {
        require(!revenueTokenConfigs[revenueToken].disabled, "Token disabled");
        revenueTokenConfigs[revenueToken].disabled = true;
    }

    /// @inheritdoc IRevenueHandler
    function enableRevenueToken(address revenueToken) external override onlyOwner {
        require(revenueTokenConfigs[revenueToken].disabled, "Token enabled");
        revenueTokenConfigs[revenueToken].disabled = false;
    }

    /// @inheritdoc IRevenueHandler
    function setTreasury(address _treasury) external override onlyOwner {
        require(_treasury != address(0), "treasury cannot be 0x0");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    /// @inheritdoc IRevenueHandler
    function setTreasuryPct(uint256 _treasuryPct) external override onlyOwner {
        require(_treasuryPct <= BPS, "treasury pct too large");
        require(_treasuryPct != treasuryPct, "treasury pct unchanged");
        treasuryPct = _treasuryPct;
        emit TreasuryPctUpdated(_treasuryPct);
    }

    /*
        User functions
    */

    /// @inheritdoc IRevenueHandler
    function claim(
        uint256 tokenId,
        address alchemist,
        uint256 amount,
        address recipient
    ) external override {
        require(IVotingEscrow(veALCX).isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");

        address debtToken = IAlchemistV2(alchemist).debtToken();
        uint256 amountClaimable = _claimable(tokenId, debtToken);
        require(amount <= amountClaimable, "Not enough claimable");

        userCheckpoints[tokenId][debtToken].lastClaimEpoch = currentEpoch;
        userCheckpoints[tokenId][debtToken].unclaimed = amountClaimable - amount;

        IERC20(debtToken).approve(alchemist, amount);
        uint256 amountBurned = IAlchemistV2(alchemist).burn(amount, recipient);

        /*
            burn() will only burn up to total cdp debt
            send the leftover directly to the user
        */
        if (amountBurned < amount) {
            IERC20(debtToken).safeTransfer(recipient, amount - amountBurned);
        }
        emit ClaimRevenue(tokenId, debtToken, amount, recipient);
    }

    /// @inheritdoc IRevenueHandler
    function checkpoint() public {
        // only run checkpoint() once per epoch
        if (
            block.timestamp >= currentEpoch + WEEK
        ) {
            currentEpoch = (block.timestamp / WEEK) * WEEK;

            for (uint256 i = 0; i < revenueTokens.length; i++) {
                // If a revenue token is disabled, skip it.
                if (revenueTokenConfigs[revenueTokens[i]].disabled) continue;

                uint256 treasuryAmt = IERC20(revenueTokens[i]).balanceOf(address(this)) * treasuryPct / BPS;
                IERC20(revenueTokens[i]).safeTransfer(treasury, treasuryAmt);
                uint256 amountReceived = _melt(revenueTokens[i]);
                console.log("revenue", amountReceived);
                epochRevenues[currentEpoch][revenueTokenConfigs[revenueTokens[i]].debtToken] += amountReceived;
                emit RevenueRealized(currentEpoch, revenueTokens[i], revenueTokenConfigs[revenueTokens[i]].debtToken, amountReceived, treasuryAmt);
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
        /*  
            minimumAmountOut == inputAmount
            Here we are making the assumption that the price of the alAsset will always be at or below the price of the revenue token.
            This is currently a safe assumption since this imbalance has always held true for alUSD and alETH since their inceptions.
        */
        return
            IPoolAdapter(poolAdapter).melt(
                revenueToken,
                tokenConfig.debtToken,
                revenueTokenBalance,
                revenueTokenBalance
            );
    }

    function _claimable(uint256 tokenId, address debtToken) internal view returns (uint256) {
        uint256 totalClaimable = 0;
        uint256 lastClaimEpoch = userCheckpoints[tokenId][debtToken].lastClaimEpoch;
        if (lastClaimEpoch == 0) {
            /*
                If we get here, the user has not yet claimed anything from the RevenueHandler.
                We need to get the first epoch that they deposited so we know where to start tallying from.
            */
            uint256 lastUserEpoch = IVotingEscrow(veALCX).userFirstEpoch(tokenId);
            lastClaimEpoch = (IVotingEscrow(veALCX).pointHistoryTimestamp(lastUserEpoch) / WEEK) * WEEK - WEEK;
        }
        /*
            Start tallying from the "next" epoch after the last epoch that they claimed, since they already
            claimed their revenue from "lastClaimEpoch".
        */
        for (uint256 epoch = lastClaimEpoch + WEEK; epoch <= currentEpoch; epoch += WEEK) {
            uint256 epochRevenue = epochRevenues[epoch][debtToken];
            uint256 epochUserVeBalance = IVotingEscrow(veALCX).balanceOfTokenAt(tokenId, epoch);
            uint256 epochTotalVeSupply = IVotingEscrow(veALCX).totalSupplyAtT(epoch);
            console.log(epoch, epochRevenue, epochUserVeBalance, epochTotalVeSupply);
            totalClaimable += (epochRevenue * epochUserVeBalance) / epochTotalVeSupply;
            console.log("claimable", totalClaimable);
        }
        return totalClaimable + userCheckpoints[tokenId][debtToken].unclaimed;
    }
}
