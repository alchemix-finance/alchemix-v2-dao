pragma solidity ^0.8.15;

interface ICurveStableSwap {
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external payable returns (uint256);
}
