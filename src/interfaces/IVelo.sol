pragma solidity ^0.8.15;

interface IVelo {
    function approve(address spender, uint256 value) external returns (bool);

    function mint(address, uint256) external;

    function mintToRedemptionReceiver(uint256) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}
