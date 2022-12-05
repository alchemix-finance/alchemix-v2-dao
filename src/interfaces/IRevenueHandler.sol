// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

interface IRevenueHandler {
    /// @notice Emitted when poolAdapter parameters are set for a revenue token.
    ///
    /// @param revenueToken     The address of the revenue token.
    /// @param poolAdapter      The address of the target pool adapter contract to call.
    event SetPoolAdapter(
        address revenueToken,
        address poolAdapter
    );

    /// @notice Emitted when a debt token is set for a revenue token.
    ///
    /// @param revenueToken The address of the token to be recognized as revenue.
    /// @param debtToken    The address of the alchemic-token that will be bought using the revenue token.
    event SetDebtToken(
        address revenueToken,
        address debtToken
    );

    /// @notice Emitted when a debt token is set for a revenue token.
    ///
    /// @param tokenId      The veALCX tokenId claiming revenue. 
    /// @param debtToken    The address of the alchemic-token that was claimed.
    /// @param amount       The amount of `debtToken` that was claimed.
    /// @param recipient    The recipient of the claim.
    event ClaimRevenue(
        uint256 tokenId,
        address debtToken,
        uint256 amount,
        address recipient
    );

    /// @notice Returns the total amount of debtToken currently claimable by tokenId.
    /// @notice This function will return the amount of claimable accrued revenue up until the most recent checkpoint.
    /// @notice If `checkpoint()` has not been called in the current epoch, then calling `claimable()`
    /// @notice will not return the claimable accrued revenue for the current epoch.
    ///
    /// @param tokenId      The tokenId with a claimable balance.
    /// @param debtToken    The debtToken that is claimable.
    ///
    /// @return             The amount of debtToken that is claimable by tokenId.
    function claimable(uint256 tokenId, address debtToken) external view returns (uint256);

    /// @notice Add an debtToken to the list of claimable debtTokens.
    /// @notice This function is only callable by the contract owner.
    ///
    /// @param debtToken    The address of the debt token to add.
    function addDebtToken(address debtToken) external;

    /// @notice Remove an debtToken from the list of claimable debtTokens.
    /// @notice This function is only callable by the contract owner.
    ///
    /// @param debtToken    The address of the debt token to remove.
    function removeDebtToken(address debtToken) external;

    /// @notice Add an revenueToken to the list of claimable revenueTokens.
    /// @notice This function is only callable by the contract owner.
    ///
    /// @param revenueToken    The address of the revenue token to add.
    function addRevenueToken(address revenueToken) external;

    /// @notice Remove an revenueToken from the list of claimable revenueTokens.
    /// @notice This function is only callable by the contract owner.
    ///
    /// @param revenueToken    The address of the revenue token to remove.
    function removeRevenueToken(address revenueToken) external;

    /// @dev Add an ERC20 token to the list of recognized revenue tokens.
    ///
    /// @param revenueToken The address of the token to be recognized as revenue.
    /// @param debtToken    The address of the alchemic-token that will be bought using the revenue token.
    function setDebtToken(address revenueToken, address debtToken) external;

    /// @dev Add call data for interactin with a pool adapter.
    ///
    /// @param revenueToken     The address of the revenue token.
    /// @param poolAdapter      The address of the target pool adapter contract to call.
    function setPoolAdapter(address revenueToken, address poolAdapter) external;

    /// @dev Disable a revenue token.
    ///
    /// @param revenueToken     The address of the revenue token.
    function disableRevenueToken(address revenueToken) external;

    /// @dev Enable a revenue token.
    ///
    /// @param revenueToken     The address of the revenue token.
    function enableRevenueToken(address revenueToken) external;

    /// @dev Claim an alotted amount of alchemic-tokens and burn them to a position in the alchemist.
    ///
    /// @notice This function will claim accrued revenue up until the most recent checkpoint.
    /// @notice If `checkpoint()` has not been called in the current epoch, then calling `claim()`
    /// @notice will not claim accrued revenue for the current epoch.
    ///
    /// @param tokenId      The ID of the veALCX position to use.
    /// @param alchemist    The address of the target alchemist.
    /// @param amount       The amount to claim.
    /// @param recipient    The recipient of the resulting credit.
    function claim(uint256 tokenId, address alchemist, uint256 amount, address recipient) external;

    /// @notice Checkpoint the current epoch.
    /// @notice This function should be run once per epoch.
    function checkpoint() external;
}