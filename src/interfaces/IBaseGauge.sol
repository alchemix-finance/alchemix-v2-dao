pragma solidity ^0.8.15;

interface IBaseGauge {
    enum VotingStage {
        BribesPhase,
        VotesPhase,
        RewardsPhase
    }

    /// @notice A checkpoint for marking balance
    struct Checkpoint {
        uint256 timestamp;
        uint256 balanceOf;
        bool voted;
    }

    /// @notice A checkpoint for marking supply
    struct SupplyCheckpoint {
        uint256 timestamp;
        uint256 supply;
    }

    function setVoteStatus(address account, bool voted) external;

    function getPriorBalanceIndex(address account, uint256 timestamp) external returns (uint256);

    function getPriorSupplyIndex(uint256 timestamp) external returns (uint256);
}
