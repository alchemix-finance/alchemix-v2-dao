// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {DSTest} from "ds-test/test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {ve} from "../veALCX.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {Hevm} from "./utils/Hevm.sol";

interface Vm {
    function prank(address) external;
}

/// @dev See https://onbjerg.github.io/foundry-book/forge/writing-tests.html for details on how this is run
/// @dev See https://onbjerg.github.io/foundry-book/reference/ds-test.html for assertions list
/// @dev See https://onbjerg.github.io/foundry-book/reference/cheatcodes.html for cheatcodes like prank()
/// @dev asserts are (actual, expected)
contract veALCXTest is DSTestPlus {
    IERC20 public alcx = IERC20(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
    IERC20 public galcx = IERC20(0x93Dede06AE3B5590aF1d4c111BC54C3f717E4b35);
    address holder = 0x000000000000000000000000000000000000dEaD;
    ve veALCX;

    uint depositAmount = 999 ether;

    /// @dev Deploy the contract
    function setUp() public {
        veALCX = new ve(address(alcx));
    }

    function testVEALCXBasic() public {

    }


}
