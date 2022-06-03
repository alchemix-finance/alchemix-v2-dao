// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {MemoProcessor} from "../MemoProcessor.sol";

import "forge-std/console2.sol";
import {DSTest} from "ds-test/test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {ve} from "../veALCX.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {Hevm} from "./utils/Hevm.sol";

interface Vm {
    function prank(address) external;
}

contract MemoProcessorTest is DSTestPlus {
    address listener = 0x000000000000000000000000000000000000dEaD;
    MemoProcessor memoProcessor;
    bytes4 testFunctionSig = 0x92d11b2d; // keccak256(receiveMemo(address))

    address memoData;

    /// @dev Deploy the contract
    function setUp() public {
        memoProcessor = new MemoProcessor();
        memoProcessor.registerSource(address(this));
        memoProcessor.registerListener(testFunctionSig, address(this));
    }

    function receiveMemo(address _memoData) external {
        memoData = _memoData;
    }

    function testMemoReceived() public {
        address testAddress = 0x000000000000000000000000000000000000bEEF;
        memoProcessor.processMemo(abi.encodeWithSignature("receiveMemo(address)", testAddress));
        assertEq(testAddress, memoData);
    }

    function testAddListener() public {
        address testAddress = 0x000000000000000000000000000000000000bEEF;
        memoProcessor.registerListener(testFunctionSig, testAddress);
        bool test = memoProcessor.isListener(testFunctionSig, testAddress);
        assert(test);
    }

    function testRemoveListener() public {
        memoProcessor.deRegisterListener(testFunctionSig, address(this));
        bool test = memoProcessor.isListener(testFunctionSig, address(this));
        assert(!test);
    }
}
