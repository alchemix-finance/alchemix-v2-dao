pragma solidity 0.8.13;

import "./interfaces/IMemoProcessor.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/v2-foundry/src/base/ErrorMessages.sol";

contract MemoProcessor is IMemoProcessor, Ownable {
    /// @dev A mapping of registered sources that can send memos.
    mapping(address => bool) public sources;

    /// @dev A mapping of memo signatures to lists of listeners.
    mapping(bytes4 => address[]) public listeners;

    constructor() Ownable() {

    }

    modifier onlySource() {
        if (!sources[msg.sender]) {
            revert Unauthorized("MemoProcessor: only source");
        }
        _;
    }

    /// @inheritdoc IMemoProcessor
    function processMemo(bytes calldata eventData) external onlySource {
        bytes4 memoSig;
        assembly {
            memoSig := calldataload(eventData.offset)
        }
        for (uint256 i = 0; i < listeners[memoSig].length; i++) {
            listeners[memoSig][i].call(eventData);
        }
        emit MemoProcessed(eventData);
    }

    /// @inheritdoc IMemoProcessor
    function registerSource(address source) external onlyOwner {
        sources[source] = true;
        emit SourceRegistered(source);
    }

    /// @inheritdoc IMemoProcessor
    function deRegisterSource(address source) external onlyOwner {
        sources[source] = false;
        emit SourceDeRegistered(source);
    }

    /// @inheritdoc IMemoProcessor
    function registerListener(bytes4 memoSig, address listener) external onlyOwner {
        for (uint256 i = 0; i < listeners[memoSig].length; i++) {
            if (listeners[memoSig][i] == listener) {
                revert IllegalArgument("MemoProcessor: listener exists");
            }
        }
        listeners[memoSig].push(listener);
        emit ListenerRegistered(memoSig, listener);
    }
    
    /// @inheritdoc IMemoProcessor
    function deRegisterListener(bytes4 memoSig, address listener) external onlyOwner {
        for (uint256 i = 0; i < listeners[memoSig].length; i++) {
            if (listeners[memoSig][i] == listener) {
                listeners[memoSig][i] = listeners[memoSig][listeners[memoSig].length - 1];
                listeners[memoSig].pop();
                emit ListenerDeRegistered(memoSig, listener);
                return;
            }
        }
        revert IllegalArgument("MemoProcessor: listener does not exist");
    }
}