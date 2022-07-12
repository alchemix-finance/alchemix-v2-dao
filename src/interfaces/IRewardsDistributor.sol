pragma solidity ^0.8.15;

interface IRewardsDistributor {
    function checkpoint_token() external;
    function checkpoint_total_supply() external;
}
