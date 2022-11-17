// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "./interfaces/IPoolAdapter.sol";
import "./interfaces/curve/ICurveMetaSwap.sol";
import "./interfaces/curve/ICurveStableSwap.sol";
import "./libraries/TokenUtils.sol";
import "./interfaces/IWETH9.sol";

contract CurveEthPoolAdapter is IPoolAdapter {
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public override pool;

    mapping(address => int128) public tokenIds;
    bool public isMetapool;

    constructor(address _pool, address[] memory _tokens) {
        pool = _pool;
        for (uint256 i; i < _tokens.length; i++) {
            tokenIds[_tokens[i]] = int128(int256(i));
        }
    }

    function getDy(address inputToken, address outputToken, uint256 inputAmount) external view override returns (uint256) {
        return ICurveStableSwap(pool).get_dy(tokenIds[inputToken], tokenIds[outputToken], inputAmount);
    }

    function melt(address inputToken, address outputToken, uint256 inputAmount, uint256 minimumAmountOut) external override returns (uint256) {
        IWETH9(weth).withdraw(inputAmount);
        return ICurveStableSwap(pool).exchange{value: inputAmount}(tokenIds[inputToken], tokenIds[outputToken], inputAmount, minimumAmountOut, msg.sender);
    }

    receive() external payable {

    }
}