// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

interface IVotiumBribe {
    function depositBribe(
        address _token,
        uint256 _amount,
        bytes32 _proposal,
        uint256 _choiceIndex
    ) external;
}
