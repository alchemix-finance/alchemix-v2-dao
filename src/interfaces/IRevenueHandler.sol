// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.13;

interface IRevenueHandler {
    /// @notice Parameters to define actions with respect to melting a revenue token for alchemic-tokens.
    struct RevenueTokenConfig {
        /// The target alchemic-token.
        address debtToken;
        /// A list of DEXs where revenue token can be traded for `debtToken`.
        address[] dexes;
        /// External call definitions to check various DEXs for trading price.
        mapping(address => bytes) checkCalls;
        /// External call definitions to execute trades on various DEXs.
        mapping(address => bytes) executeCalls;
    }

    /// @notice Emitted when dex parameters are set for a revenue token.
    ///
    /// @param revenueToken     The address of the revenue token.
    /// @param dex              The address of the target DEX contract to call.
    /// @param checkCallData    The hexified call data to be used in the low-level `staticcall` that checks the price of the trade.
    /// @param executeCallData  The hexified call data to be used in the low-level `call` that executes the trade.
    event SetDex(
        address revenueToken,
        address dex,
        bytes checkCallData,
        bytes executeCallData
    );

    /// @notice Emitted when a debt token is set for a revenue token.
    ///
    /// @param revenueToken The address of the token to be recognized as revenue.
    /// @param debtToken    The address of the alchemic-token that will be bought using the revenue token.
    event SetDebtToken(
        address revenueToken,
        address debtToken
    );

    /// @dev Add an ERC20 token to the list of recognized revenue tokens.
    ///
    /// @param revenueToken The address of the token to be recognized as revenue.
    /// @param debtToken    The address of the alchemic-token that will be bought using the revenue token.
    function setDebtToken(address revenueToken, address debtToken) external;

    /// @dev Add call data for interactin with a DEX.
    ///
    /// @param revenueToken     The address of the revenue token.
    /// @param dex              The address of the target DEX contract to call.
    /// @param checkCallData    The hexified call data to be used in the low-level `staticcall` that checks the price of the trade.
    /// @param executeCallData  The hexified call data to be used in the low-level `call` that executes the trade.
    function setDex(address revenueToken, address dex, bytes calldata checkCallData, bytes calldata executeCallData) external;

    /// @dev Execute a trade on a DEX to purhcase alchemic-tokens using revenue tokens.
    ///
    /// @param revenueToken The revenue token to melt.
    function melt(address revenueToken) external;

    /// @dev Claim an alotted amount of alchemic-tokens and burn them to a position in the alchemist.
    ///
    /// @param alchemist    The address of the target alchemist.
    /// @param amount       The amount of alchemic-tokens to burn.
    /// @param recipient    The recipient of the resulting credit.
    function claim(address alchemist, uint256 amount, address recipient) external;
}