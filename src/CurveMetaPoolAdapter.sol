// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "./interfaces/IPoolAdapter.sol";
import "./interfaces/curve/ICurveMetaSwap.sol";
import "./interfaces/curve/ICurveStableSwap.sol";
import "./libraries/TokenUtils.sol";
import "./interfaces/IWETH9.sol";

contract CurveMetaPoolAdapter is IPoolAdapter {
    address public override pool;

    mapping(address => int128) public tokenIds;

    constructor(address _pool, address[] memory _tokens) {
        pool = _pool;
        for (uint256 i; i < _tokens.length; i++) {
            tokenIds[_tokens[i]] = int128(int256(i));
        }
    }

    function getDy(address inputToken, address outputToken, uint256 inputAmount) external view override returns (uint256) {
        return ICurveMetaSwap(pool).get_dy_underlying(tokenIds[inputToken], tokenIds[outputToken], inputAmount);
    }

    function melt(address inputToken, address outputToken, uint256 inputAmount, uint256 minimumAmountOut) external override returns (uint256) {
        TokenUtils.safeApprove(inputToken, pool, inputAmount);
        return ICurveMetaSwap(pool).exchange_underlying(tokenIds[inputToken], tokenIds[outputToken], inputAmount, minimumAmountOut, msg.sender);
    }
}