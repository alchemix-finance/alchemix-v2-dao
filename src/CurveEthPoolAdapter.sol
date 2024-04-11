// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "src/interfaces/IPoolAdapter.sol";
import "src/interfaces/curve/ICurveMetaSwap.sol";
import "src/interfaces/curve/ICurveStableSwap.sol";
import "src/libraries/TokenUtils.sol";
import "src/interfaces/IWETH9.sol";

contract CurveEthPoolAdapter is IPoolAdapter {
    address public immutable override pool;

    mapping(address => int128) public tokenIds;
    bool public isMetapool;

    address public immutable weth;

    constructor(address _pool, address[] memory _tokens, address _weth) {
        weth = _weth;
        pool = _pool;
        for (uint256 i; i < _tokens.length; i++) {
            tokenIds[_tokens[i]] = int128(int256(i));
        }
    }

    // please describe this function and format for the documentation
    function getDy(
        address inputToken,
        address outputToken,
        uint256 inputAmount
    ) external view override returns (uint256) {
        return ICurveStableSwap(pool).get_dy(tokenIds[inputToken], tokenIds[outputToken], inputAmount);
    }

    // please describe this function and format for the documentation
    function melt(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 minimumAmountOut
    ) external override returns (uint256) {
        IWETH9(weth).withdraw(inputAmount);
        return
            ICurveStableSwap(pool).exchange{ value: inputAmount }(
                tokenIds[inputToken],
                tokenIds[outputToken],
                inputAmount,
                minimumAmountOut,
                msg.sender
            );
    }

    receive() external payable {}
}
