// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.13;

import "./interfaces/IRevenueHandler.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/v2-foundry/src/interfaces/IAlchemistV2.sol";

contract RevenueHandler is IRevenueHandler, Ownable {
    mapping(address => RevenueTokenConfig) public revenueTokens;

    constructor() Ownable() {

    }

    /// @inheritdoc IRevenueHandler
    function setDebtToken(address revenueToken, address debtToken) external override onlyOwner {
        revenueTokens[revenueToken].debtToken = debtToken;
    }

    /// @inheritdoc IRevenueHandler
    function setDex(address revenueToken, address dex, bytes calldata checkCallData, bytes calldata executeCallData) external override onlyOwner {
        revenueTokens[revenueToken].dexes.push(dex);
        revenueTokens[revenueToken].checkCalls[dex] = checkCallData;
        revenueTokens[revenueToken].executeCalls[dex] = executeCallData;
    }

    /// @inheritdoc IRevenueHandler
    function melt(address revenueToken) external override {

    }

    /// @inheritdoc IRevenueHandler
    function claim(address alchemist, uint256 amount, address recipient) external override {
        IAlchemistV2(alchemist).burn(amount, recipient);
    }
}