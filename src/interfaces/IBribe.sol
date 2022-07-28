pragma solidity ^0.8.15;

interface IBribe {
    function notifyRewardAmount(address token, uint256 amount) external;

    function setGauge(address _gauge) external;

    function getEpochStart(uint256 timestamp) external view returns (uint256);

    function deliverReward(address token, uint256 epochStart)
        external
        returns (uint256);

    function rewardsListLength() external view returns (uint256);

    function rewards(uint256 i) external view returns (address);

    function addRewardToken(address token) external;

    function swapOutRewardToken(
        uint256 i,
        address oldToken,
        address newToken
    ) external;
}
