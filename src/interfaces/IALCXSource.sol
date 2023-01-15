// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

interface IALCXSource {
    function getStakeTotalDeposited(address _user, uint256 _poolId) external view returns (uint256);

    function claim(uint256 _poolId) external;

    function deposit(uint256 _poolId, uint256 _depositAmount) external;

    function withdraw(uint256 _poolId, uint256 _withdrawAmount) external;
}
