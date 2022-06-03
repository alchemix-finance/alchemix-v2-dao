pragma solidity 0.8.13;

interface IMemoProcessor {
    function processMemo(bytes calldata eventData) external;
    function registerSource(address source) external;
    function deRegisterSource(address source) external;
    function registerListener(bytes4 memoSig, address listener) external;
    function deRegisterListener(bytes4 memoSig, address listener) external;
}