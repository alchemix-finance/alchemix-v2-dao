pragma solidity ^0.8.15;

interface IRewardsDistributor {
    function checkpointToken() external;

    function checkpointTotalSupply() external;
}
