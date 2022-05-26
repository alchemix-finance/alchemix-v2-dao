// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.13;

import "./interfaces/IPoolAdaptor.sol";
import "./interfaces/curve/ICurveMetaSwap.sol";
import "./interfaces/curve/ICurveStableSwap.sol";
import "../lib/v2-foundry/src/libraries/TokenUtils.sol";

contract CurvePoolAdaptor is IPoolAdaptor {
    address public override pool;

    mapping(address => int128) public tokenIds;
    bool public isMetapool;

    constructor(address _pool, address[] memory _tokens, bool _isMetapool) {
        pool = _pool;
        for (uint256 i; i < _tokens.length; i++) {
            tokenIds[_tokens[i]] = int128(int256(i));
        }
        isMetapool = _isMetapool;
    }

    function getDy(address inputToken, address outputToken, uint256 inputAmount) external override returns (uint256) {
        if (isMetapool) {
            return ICurveMetaSwap(pool).get_dy(tokenIds[inputToken], tokenIds[outputToken], inputAmount);
        } else {
            return ICurveMetaSwap(pool).get_dy_underlying(tokenIds[inputToken], tokenIds[outputToken], inputAmount);
        }
    }

    function melt(address inputToken, address outputToken, uint256 inputAmount, uint256 minimumAmountOut) external override returns (uint256) {
        TokenUtils.safeApprove(inputToken, pool, inputAmount);
        if (isMetapool) {
            return ICurveMetaSwap(pool).exchange_underlying(tokenIds[inputToken], tokenIds[outputToken], inputAmount, minimumAmountOut, msg.sender);
        } else {
            return ICurveStableSwap(pool).exchange(tokenIds[inputToken], tokenIds[outputToken], inputAmount, minimumAmountOut, msg.sender);
        }
    }
}