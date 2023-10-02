// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IFluxToken is IERC20 {
    event AdminUpdated(address admin);

    /**
     * @notice Set the address responsible for administration
     * @param _admin Address that enables the administration of FLUX
     * @dev This function reverts if the caller does not have the admin role.
     */
    function setAdmin(address _admin) external;

    /**
     * @notice Accept the address responsible for administration
     * @dev This function reverts if the caller does not have the pendingAdmin role.
     */
    function acceptAdmin() external;

    /**
     * @notice Set the voting contract address
     * @param _voter Voter contract address
     * @dev This function reverts if the caller does not have the admin role.
     */
    function setVoter(address _voter) external;

    /**
     * @notice Set the veALCX contract address
     * @param _veALCX veALCX contract address
     * @dev This function reverts if the caller does not have the admin role.
     */
    function setVeALCX(address _veALCX) external;

    /**
     * @notice Set the address responsible for minting
     * @param _minter Address that enables the minting of FLUX
     * @dev This function reverts if the caller does not have the minter role.
     */
    function setMinter(address _minter) external;

    /**
     * @notice Mints tokens to a recipient.
     * @param _recipient the account to mint tokens to.
     * @param _amount    the amount of tokens to mint.
     * @dev This function reverts if the caller does not have the minter role.
     */
    function mint(address _recipient, uint256 _amount) external;

    /**
     * @dev Burns `amount` tokens from `account`, deducting from the caller's allowance.
     * @param _account The address the burn tokens from.
     * @param _amount  The amount of tokens to burn.
     */
    function burnFrom(address _account, uint256 _amount) external;

    /**
     * @notice Get the amount of unclaimed flux for a given veALCX tokenId
     * @param _tokenId ID of the token to get unclaimed flux for
     * @return Amount of unclaimed flux
     */
    function getUnclaimedFlux(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Merge the unclaimed flux from one token into another
     * @param _fromTokenId The token to merge from
     * @param _toTokenId   The token to merge to
     */
    function mergeFlux(uint256 _fromTokenId, uint256 _toTokenId) external;

    /**
     * @notice Accrue unclaimed flux for a given veALCX
     * @param _tokenId ID of the token flux is being accrued to
     * @param _amount Amount of flux being accrued
     */
    function accrueFlux(uint256 _tokenId, uint256 _amount) external;

    /**
     * @notice Update unclaimed flux balance for a given veALCX
     * @param _tokenId ID of the token flux is being updated for
     * @param _amount Amount of flux being used
     */
    function updateFlux(uint256 _tokenId, uint256 _amount) external;

    /**
     * @notice Claim unclaimed flux for a given token
     * @param _tokenId ID of the token flux is being claimed for
     * @param _amount Amount of flux being claimed
     */
    function claimFlux(uint256 _tokenId, uint256 _amount) external;
}
