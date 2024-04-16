// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

interface IPoolAdapter {
    /**
     * @notice Get the address of the pool
     */
    function pool() external view returns (address);

    /**
     * @notice Get the amount of output token for a given input token and amount
     * @param inputToken input token address
     * @param outputToken output token address
     * @param inputAmount input token amount
     */
    function getDy(address inputToken, address outputToken, uint256 inputAmount) external view returns (uint256);

    /**
     * @notice Melt the input token to the output token
     * @param inputToken input token address
     * @param outputToken output token address
     * @param inputAmount input token amount
     * @param minimumAmountOut minimum output token amount
     */
    function melt(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 minimumAmountOut
    ) external returns (uint256);
}
