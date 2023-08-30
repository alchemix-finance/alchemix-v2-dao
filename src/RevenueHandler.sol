// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "lib/forge-std/src/console2.sol";

import "src/interfaces/IRevenueHandler.sol";
import "src/interfaces/IPoolAdapter.sol";
import "src/interfaces/IVotingEscrow.sol";
import "lib/v2-foundry/src/interfaces/IAlchemistV2.sol";
import "lib/v2-foundry/src/base/ErrorMessages.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title RevenueHandler
/*
    This contract is meant to receive all revenue from the Alchemix protocol, and allow
        veALCX stakers to claim it, primarily as a form of debt repayment.
    IPoolAdapter contracts are used to plug into various DEXes so that revenue tokens (dai, usdc, weth, etc)
        can be traded for alAssets (alUSD, alETH, etc). Once per epoch (at the beginning of the epoch)
        the `checkpoint()` function needs to be called so that any revenue accrued since the last checkpoint
        can be melted into its relative alAsset. After `checkpoint()` is called, the current epoch's revenue
        is available to be claimed by veALCX stakers (as long as they were staked before `checkpoint()` was
        called).
    veALCX stakers can claim some or all of their available revenue. When a staker calls `claim()`, they
        choose an amount, target alchemist, and target recipient. The RevenueHandler will `burn()` up to
        `amount` of the alAsset used by `alchemist` on `recipient`'s account. Any leftover revenue that
        is not burned will be sent directly to `recipient.
    Any revenue that is not an Alchemix protocol debt token will be sent directly to users
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
    address[] public revenueTokens;
    mapping(address => bool) public alchemicTokens; // token => is alchemic-token (true/false)
    mapping(address => RevenueTokenConfig) public revenueTokenConfigs; // token => RevenueTokenConfig
    mapping(uint256 => mapping(address => uint256)) public epochRevenues; // epoch => (debtToken => epoch revenue)
    mapping(uint256 => mapping(address => Claimable)) public userCheckpoints; // tokenId => (debtToken => Claimable)
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
    function claimable(uint256 tokenId, address token) external view override returns (uint256) {
        return _claimable(tokenId, token);
    }

    /*
        Admin functions
    */

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
    function addAlchemicToken(address alchemicToken) external override onlyOwner {
        require(!alchemicTokens[alchemicToken], "alchemic token already exists");
        alchemicTokens[alchemicToken] = true;

        emit AlchemicTokenAdded(alchemicToken);
    }

    /// @inheritdoc IRevenueHandler
    function removeAlchemicToken(address alchemicToken) external override onlyOwner {
        require(alchemicTokens[alchemicToken], "alchemic token does not exist");
        alchemicTokens[alchemicToken] = false;

        emit AlchemicTokenRemoved(alchemicToken);
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
        address token,
        address alchemist,
        uint256 amount,
        address recipient
    ) external override {
        require(IVotingEscrow(veALCX).isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");

        uint256 amountBurned = 0;

        uint256 amountClaimable = _claimable(tokenId, token);
        require(amount <= amountClaimable, "Not enough claimable");
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= IERC20(token).balanceOf(address(this)), "Not enough revenue to claim");

        userCheckpoints[tokenId][token].lastClaimEpoch = currentEpoch;
        userCheckpoints[tokenId][token].unclaimed = amountClaimable - amount;

        if (alchemicTokens[token]) {
            require(alchemist != address(0), "if token is alchemic-token, alchemist must be set");

            (, address[] memory deposits) = IAlchemistV2(alchemist).accounts(recipient);
            IERC20(token).approve(alchemist, amount);

            // Only burn if there are deposits
            amountBurned = deposits.length > 0 ? IAlchemistV2(alchemist).burn(amount, recipient) : 0;
        }

        /*
            burn() will only burn up to total cdp debt
            send the leftover directly to the user
        */
        if (amountBurned < amount) {
            IERC20(token).safeTransfer(recipient, amount - amountBurned);
        }

        emit ClaimRevenue(tokenId, token, amount, recipient);
    }

    /// @inheritdoc IRevenueHandler
    function checkpoint() public {
        // only run checkpoint() once per epoch
        if (block.timestamp >= currentEpoch + WEEK /* && initializer == address(0) */) {
            currentEpoch = (block.timestamp / WEEK) * WEEK;

            for (uint256 i = 0; i < revenueTokens.length; i++) {
                // These will be zero if the revenue token is not an alchemic-token
                uint256 treasuryAmt = 0;
                uint256 amountReceived = 0;
                address token = revenueTokens[i];

                // If a revenue token is disabled, skip it.
                if (revenueTokenConfigs[token].disabled) continue;

                // If poolAdapter is set, the revenue token is an alchemic-token
                if (revenueTokenConfigs[token].poolAdapter != address(0)) {
                    // Treasury only receives revenue if the token is an alchemic-token
                    treasuryAmt = (IERC20(token).balanceOf(address(this)) * treasuryPct) / BPS;
                    IERC20(token).safeTransfer(treasury, treasuryAmt);

                    // Only melt if there is an alchemic-token to melt to
                    amountReceived = _melt(token);

                    // Update amount of alchemic-token revenue received for this epoch
                    epochRevenues[currentEpoch][revenueTokenConfigs[token].debtToken] += amountReceived;
                } else {
                    // If the revenue token doesn't have a poolAdapter, it is not an alchemic-token
                    amountReceived = IERC20(token).balanceOf(address(this));

                    // Update amount of non-alchemic-token revenue received for this epoch
                    epochRevenues[currentEpoch][token] += amountReceived;
                }

                emit RevenueRealized(
                    currentEpoch,
                    token,
                    revenueTokenConfigs[revenueTokens[i]].debtToken,
                    amountReceived,
                    treasuryAmt
                );
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

    function _claimable(uint256 tokenId, address token) internal view returns (uint256) {
        uint256 totalClaimable = 0;
        uint256 lastClaimEpochTimestamp = userCheckpoints[tokenId][token].lastClaimEpoch;
        if (lastClaimEpochTimestamp == 0) {
            /*
                If we get here, the user has not yet claimed anything from the RevenueHandler.
                We need to get the first epoch that they deposited so we know where to start tallying from.
            */
            // Get index of first epoch
            uint256 lastUserEpoch = IVotingEscrow(veALCX).userFirstEpoch(tokenId);
            // Get timestamp from index
            lastClaimEpochTimestamp = (IVotingEscrow(veALCX).pointHistoryTimestamp(lastUserEpoch) / WEEK) * WEEK - WEEK;
        }
        /*
            Start tallying from the "next" epoch after the last epoch that they claimed, since they already
            claimed their revenue from "lastClaimEpochTimestamp".
        */
        for (
            uint256 epochTimestamp = lastClaimEpochTimestamp + WEEK;
            epochTimestamp <= currentEpoch;
            epochTimestamp += WEEK
        ) {
            uint256 epochTotalVeSupply = IVotingEscrow(veALCX).totalSupplyAtT(epochTimestamp);
            if (epochTotalVeSupply == 0) continue;
            uint256 epochRevenue = epochRevenues[epochTimestamp][token];
            uint256 epochUserVeBalance = IVotingEscrow(veALCX).balanceOfTokenAt(tokenId, epochTimestamp);
            totalClaimable += (epochRevenue * epochUserVeBalance) / epochTotalVeSupply;
        }
        return totalClaimable + userCheckpoints[tokenId][token].unclaimed;
    }
}
