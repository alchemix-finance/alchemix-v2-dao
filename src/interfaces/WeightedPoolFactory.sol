// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./IRateProvider.sol";

interface WeightedPoolFactory {
    function create(
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256[] memory normalizedWeights,
        IRateProvider[] memory rateProviders,
        uint256 swapFeePercentage,
        address owner
    ) external returns (address);
}
