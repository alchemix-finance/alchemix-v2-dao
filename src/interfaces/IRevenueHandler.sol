// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

interface IRevenueHandler {
    /**
     * @notice Emitted when the address of the treasury is updated.
     *
     * @param treasury The new treasury address.
     */
    event TreasuryUpdated(address treasury);

    /**
     * @notice Emitted when the treasury PCT is updated.
     *
     * @param treasuryPct The new treasury PCT value.
     */
    event TreasuryPctUpdated(uint256 treasuryPct);

    /**
     * @notice Emitted when a debt token is added.
     *
     * @param debtToken The debt token to add.
     */
    event DebtTokenAdded(address debtToken);

    /**
     * @notice Emitted when a debt token is removed.
     *
     * @param debtToken The debt token to remove.
     */
    event DebtTokenRemoved(address debtToken);

    /**
     * @notice Emitted when a revenue token is added.
     *
     * @param revenueToken The revenue token to add.
     */
    event RevenueTokenTokenAdded(address revenueToken);

    /**
     * @notice Emitted when a revenue token is removed.
     *
     * @param revenueToken The revenue token to remove.
     */
    event RevenueTokenTokenRemoved(address revenueToken);

    /**
     * @notice Emitted when alchemic-token is added.
     *
     * @param alchemicToken The alchemic-token to add
     */
    event AlchemicTokenAdded(address alchemicToken);

    /**
     * @notice Emitted when alchemic-token is removed.
     *
     * @param alchemicToken The alchemic-token to remove.
     */
    event AlchemicTokenRemoved(address alchemicToken);

    /**
     * @notice Emitted when poolAdapter parameters are set for a revenue token.
     *
     * @param revenueToken  The address of the revenue token.
     * @param poolAdapter   The address of the target pool adapter contract to call.
     */
    event SetPoolAdapter(address revenueToken, address poolAdapter);

    /**
     * @notice Emitted when a debt token is set for a revenue token.
     *
     * @param revenueToken The address of the token to be recognized as revenue.
     * @param debtToken    The address of the alchemic-token that will be bought using the revenue token.
     */
    event SetDebtToken(address revenueToken, address debtToken);

    /**
     * @notice Emitted when revenue is claimed.
     *
     * @param tokenId      The veALCX tokenId claiming revenue.
     * @param debtToken    The address of the alchemic-token that was claimed.
     * @param amount       The amount of `debtToken` that was claimed.
     * @param recipient    The recipient of the claim.
     */
    event ClaimRevenue(uint256 tokenId, address debtToken, uint256 amount, address recipient);

    /**
     * @notice Emitted when revenue is realized during a checkpoint.
     *
     * @param epochId           The veALCX tokenId claiming revenue.
     * @param revenueToken      The address of the revenue-token that was melted.
     * @param debtToken         The address of the alchemic-token to be counted as revenue.
     * @param claimableAmount   The amount of `debtToken` that can be claimed.
     * @param treasuryAmount    The amount of `revenueToken` sent to the treasury.
     */
    event RevenueRealized(
        uint256 epochId,
        address revenueToken,
        address debtToken,
        uint256 claimableAmount,
        uint256 treasuryAmount
    );

    /**
     * @notice Returns the total amount of token currently claimable by tokenId.
     * @notice This function will return the amount of claimable accrued revenue up until the most recent checkpoint.
     * @notice If `checkpoint()` has not been called in the current epoch, then calling `claimable()`
     * @notice will not return the claimable accrued revenue for the current epoch.
     *
     * @param tokenId      The tokenId with a claimable balance.
     * @param token    The token that is claimable.
     *
     * @return             The amount of token that is claimable by tokenId.
     */
    function claimable(uint256 tokenId, address token) external view returns (uint256);

    /**
     * @notice Add a revenueToken to the list of claimable revenueTokens.
     * @notice This function is only callable by the contract owner.
     *
     * @param revenueToken The address of the revenue token to add.
     */
    function addRevenueToken(address revenueToken) external;

    /**
     * @notice Remove a revenueToken from the list of claimable revenueTokens.
     * @notice This function is only callable by the contract owner.
     *
     * @param revenueToken The address of the revenue token to remove.
     */
    function removeRevenueToken(address revenueToken) external;

    /**
     * @notice Add an alchemic-token to the list of recognized alchemic-tokens.
     * @notice This function is only callable by the contract owner.
     *
     * @param alchemicToken The address of the alchemic-token to add.
     */
    function addAlchemicToken(address alchemicToken) external;

    /**
     * @notice Remove an alchemic-token from the list of recognized alchemic-tokens.
     * @notice This function is only callable by the contract owner.
     *
     * @param alchemicToken The address of the alchemic-token to remove.
     */
    function removeAlchemicToken(address alchemicToken) external;

    /**
     * @dev Add an ERC20 token to the list of recognized revenue tokens.
     *
     * @param revenueToken The address of the token to be recognized as revenue.
     * @param debtToken    The address of the alchemic-token that will be bought using the revenue token.
     */
    function setDebtToken(address revenueToken, address debtToken) external;

    /**
     * @dev Add call data for interactin with a pool adapter.
     *
     * @param revenueToken  The address of the revenue token.
     * @param poolAdapter   The address of the target pool adapter contract to call.
     */
    function setPoolAdapter(address revenueToken, address poolAdapter) external;

    /**
     * @dev Disable a revenue token.
     *
     * @param revenueToken The address of the revenue token.
     */
    function disableRevenueToken(address revenueToken) external;

    /**
     * @dev Enable a revenue token.
     *
     * @param revenueToken The address of the revenue token.
     */
    function enableRevenueToken(address revenueToken) external;

    /**
     * @dev Enable a revenue token.
     *
     * @param _treasury The new address of the treasury.
     */
    function setTreasury(address _treasury) external;

    /**
     * @dev Enable a revenue token.
     *
     * @param _treasuryPct The percentage of revenue to send to the treasury.
     */
    function setTreasuryPct(uint256 _treasuryPct) external;

    /**
     * @dev Claim an alotted amount of alchemic-tokens and burn them to a position in the alchemist.
     * @dev If token being claimed is not an alchemic-token, then it will be sent to the recipient.
     *
     * @notice This function will claim accrued revenue up until the most recent checkpoint.
     * @notice If `checkpoint()` has not been called in the current epoch, then calling `claim()`
     * @notice will not claim accrued revenue for the current epoch.
     *
     * @param tokenId      The ID of the veALCX position to use.
     * @param token        The address of the token to claim.
     * @param alchemist    The address of the target alchemist.
     * @param amount       The amount to claim.
     * @param recipient    The recipient of the resulting credit.
     */
    function claim(uint256 tokenId, address token, address alchemist, uint256 amount, address recipient) external;

    /**
     * @notice Checkpoint the current epoch.
     * @notice This function should be run once per epoch.
     */
    function checkpoint() external;
}
