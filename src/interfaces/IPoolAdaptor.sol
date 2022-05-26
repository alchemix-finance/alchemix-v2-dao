pragma solidity 0.8.13;

interface IPoolAdaptor {
    function pool() external returns (address);
    function getDy(address inputToken, address outputToken, uint256 inputAmount) external returns (uint256);
    function melt(address inputToken, address outputToken, uint256 inputAmount, uint256 minimumAmountOut) external returns (uint256);
}