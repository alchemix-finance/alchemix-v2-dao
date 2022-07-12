pragma solidity ^0.8.15;

interface IPairCallee {
    function hook(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
