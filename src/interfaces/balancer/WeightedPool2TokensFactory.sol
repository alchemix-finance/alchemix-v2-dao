// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface WeightedPool2TokensFactory {
    function create(
        string memory name,
        string memory symbol,
        address[] memory tokens,
        uint256[] memory weights,
        uint256 swapFeePercentage,
        bool oracleEnabled,
        address owner
    ) external returns (address);
}
