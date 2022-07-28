pragma solidity ^0.8.15;

interface IGaugeFactory {
    function admin() external view returns (address);
    function createGauge(address, address, address) external returns (address);
}
