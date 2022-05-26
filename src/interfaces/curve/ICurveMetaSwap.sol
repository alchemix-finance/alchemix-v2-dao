// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.13;

interface ICurveMetaSwap {
    function get_dy(int128 i, int128 j, uint256 dx) external returns (uint256);
    function get_dy_underlying(int128 i, int128 j, uint256 dx) external returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);
}
