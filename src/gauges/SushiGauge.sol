// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "src/PassthroughGauge.sol";
import "src/interfaces/IBribe.sol";
import "src/interfaces/IVotingEscrow.sol";
import "src/interfaces/IVoter.sol";

/// @title Sushi Gauge
/// @notice Gauge to handle distribution of rewards to Sushi pool
contract SushiGauge is PassthroughGauge {
    constructor(
        address _receiver,
        address _bribe,
        address _ve,
        address _voter
    ) {
        bribe = _bribe;
        ve = _ve;
        voter = _voter;
        receiver = _receiver;

        admin = IVoter(voter).executor();

        IBribe(bribe).setGauge(address(this));
        rewardToken = IVotingEscrow(ve).ALCX();
        IBribe(bribe).addRewardToken(rewardToken);
        isReward[rewardToken] = true;
        rewards.push(rewardToken);
    }
}
