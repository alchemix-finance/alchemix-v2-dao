pragma solidity ^0.8.15;

interface IGauge {
    function notifyRewardAmount(address token, uint256 amount) external;
    function getReward(address account, address[] memory tokens) external;
    function claimFees() external returns (uint256 claimed0, uint256 claimed1);
    function deliverBribes() external;
    function addBribeRewardToken(address token) external;
    function left(address token) external view returns (uint256);
    function setVoteStatus(address account, bool voted) external;
}
