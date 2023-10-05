// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "src/BaseGauge.sol";
import "src/interfaces/IBribe.sol";
import "src/interfaces/IVoter.sol";
import "src/interfaces/IVotingEscrow.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title Passthrough Gauge
 * @notice Generic gauge to handle distribution of rewards without pool specific passthrough logic
 * @dev If custom distribution logic is necessary create additional contract
 */
contract PassthroughGauge is BaseGauge {
    constructor(address _receiver, address _bribe, address _ve, address _voter) {
        receiver = _receiver;
        bribe = _bribe;
        ve = _ve;
        voter = _voter;

        admin = IVoter(voter).admin();

        IBribe(bribe).setGauge(address(this));
        rewardToken = IVotingEscrow(ve).ALCX();
        IBribe(bribe).addRewardToken(rewardToken);
    }

    /*
        Internal functions
    */

    /**
     * @notice Pass rewards to pool
     * @param _amount Amount of rewards
     */
    function _passthroughRewards(uint256 _amount) internal override {
        uint256 rewardBalance = IERC20(rewardToken).balanceOf(address(this));
        require(rewardBalance >= _amount, "insufficient rewards");

        _safeTransfer(rewardToken, receiver, _amount);

        emit Passthrough(msg.sender, rewardToken, _amount, receiver);
    }
}
