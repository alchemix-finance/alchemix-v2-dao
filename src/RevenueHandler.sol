// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.13;

import "./interfaces/IRevenueHandler.sol";
import "./interfaces/IPoolAdaptor.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/v2-foundry/src/interfaces/IAlchemistV2.sol";
import "../lib/v2-foundry/src/libraries/TokenUtils.sol";
import "../lib/v2-foundry/src/base/ErrorMessages.sol";

contract RevenueHandler is IRevenueHandler, Ownable {
    mapping(address => RevenueTokenConfig) public revenueTokens;

    constructor() Ownable() {

    }

    /// @inheritdoc IRevenueHandler
    function setDebtToken(address revenueToken, address debtToken) external override onlyOwner {
        revenueTokens[revenueToken].debtToken = debtToken;
        emit SetDebtToken(revenueToken, debtToken);
    }

    /// @inheritdoc IRevenueHandler
    function addPoolAdaptor(address revenueToken, address poolAdaptor) external override onlyOwner {
        revenueTokens[revenueToken].poolAdaptors.push(poolAdaptor);
        emit AddPoolAdaptor(revenueToken, poolAdaptor);
    }

    function removePoolAdaptor(address revenueToken, address poolAdaptor) external override onlyOwner {
        address[] storage poolAdaptors = revenueTokens[revenueToken].poolAdaptors;
        for (uint256 i = 0; i < poolAdaptors.length; i++) {
            if (poolAdaptors[i] == poolAdaptor) {
                poolAdaptors[i] = poolAdaptors[poolAdaptors.length - 1];
                poolAdaptors.pop();
                break;
            }
        }
    }

    /// @inheritdoc IRevenueHandler
    function melt(address revenueToken, address poolAdaptor) external override {
        RevenueTokenConfig storage tokenConfig = revenueTokens[revenueToken];
        uint256 revenueTokenBalance = TokenUtils.safeBalanceOf(revenueToken, address(this));
        if (revenueTokenBalance == 0) {
            revert IllegalState("revenue balance 0");
        }
        TokenUtils.safeTransfer(revenueToken, poolAdaptor, revenueTokenBalance);
        uint256 received = IPoolAdaptor(poolAdaptor).melt(revenueToken, tokenConfig.debtToken, revenueTokenBalance, 0); // TODO: fix minimum amount out
    }

    /// @inheritdoc IRevenueHandler
    function claim(address alchemist, uint256 amount, address recipient) external override {
        IAlchemistV2(alchemist).burn(amount, recipient);
    }
}