// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.13;

interface IRevenueHandler {
    /// @notice Parameters to define actions with respect to melting a revenue token for alchemic-tokens.
    struct RevenueTokenConfig {
        /// The target alchemic-token.
        address debtToken;
        /// A list of pool adpators that can be used to trade revenue token for `debtToken`.
        address[] poolAdaptors;
    }

    /// @notice Emitted when poolAdaptor parameters are set for a revenue token.
    ///
    /// @param revenueToken     The address of the revenue token.
    /// @param poolAdaptor      The address of the target pool adaptor contract to call.
    event AddPoolAdaptor(
        address revenueToken,
        address poolAdaptor
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

    /// @dev Add call data for interactin with a pool adaptor.
    ///
    /// @param revenueToken     The address of the revenue token.
    /// @param poolAdaptor      The address of the target pool adaptor contract to call.
    function addPoolAdaptor(address revenueToken, address poolAdaptor) external;

    function removePoolAdaptor(address revenueToken, address poolAdaptor) external;
    
    /// @dev Execute a trade on a pool adaptor to purhcase alchemic-tokens using revenue tokens.
    ///
    /// @param revenueToken The revenue token to melt.
    function melt(address revenueToken, address poolAdaptor) external;

    /// @dev Claim an alotted amount of alchemic-tokens and burn them to a position in the alchemist.
    ///
    /// @param alchemist    The address of the target alchemist.
    /// @param amount       The amount of alchemic-tokens to burn.
    /// @param recipient    The recipient of the resulting credit.
    function claim(address alchemist, uint256 amount, address recipient) external;
}