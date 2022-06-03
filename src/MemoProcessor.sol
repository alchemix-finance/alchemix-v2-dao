pragma solidity 0.8.13;

import "./interfaces/IMemoProcessor.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "forge-std/console2.sol";

contract MemoProcessor is IMemoProcessor, Ownable {
    error Unauthorized();
    error IllegalArgument();

    mapping(address => bool) public sources;
    mapping(bytes4 => address[]) public listeners;

    constructor() Ownable() {

    }

    modifier onlySource() {
        if (!sources[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }

    function processMemo(bytes calldata eventData) external onlySource {
        bytes4 memoSig;
        assembly {
            memoSig := calldataload(eventData.offset)
        }
        for (uint256 i = 0; i < listeners[memoSig].length; i++) {
            listeners[memoSig][i].call(eventData);
        }
    }

    function registerSource(address source) external onlyOwner {
        sources[source] = true;
    }

    function deRegisterSource(address source) external onlyOwner {
        sources[source] = false;
    }

    function registerListener(bytes4 memoSig, address listener) external onlyOwner {
        for (uint256 i = 0; i < listeners[memoSig].length; i++) {
            if (listeners[memoSig][i] == listener) {
                revert IllegalArgument();
            }
        }
        listeners[memoSig].push(listener);
    }
    
    function deRegisterListener(bytes4 memoSig, address listener) external onlyOwner {
        for (uint256 i = 0; i < listeners[memoSig].length; i++) {
            if (listeners[memoSig][i] == listener) {
                listeners[memoSig][i] = listeners[memoSig][listeners[memoSig].length - 1];
                listeners[memoSig].pop();
                break;
            }
        }
    }
}