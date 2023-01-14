// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

interface IMemoProcessor {
    /// @notice Emitted when a memo is successfully processed.
    event MemoProcessed(bytes memoData, address[] listeners);

    /// @notice Emitted when a source is registered.
    event SourceRegistered(address source);

    /// @notice Emitted when a source is de-registered.
    event SourceDeRegistered(address source);

    /// @notice Emitted when a listener is registered.
    event ListenerRegistered(bytes4 memoSig, address listener);

    /// @notice Emitted when a listener is de-registered.
    event ListenerDeRegistered(bytes4 memoSig, address listener);

    /**
     * @notice Get a list of addresses listening to a particular memo signature.
     * @param memoSig  The signature of the memo to check.
     */
    function getListeners(bytes4 memoSig) external returns (address[] memory _listeners);

    /**
     * @notice Check if a particular address is listening for a particular memo signature.
     * @param memoSig  The signature of the memo to check.
     * @param listener The address of the listener to check.
     */
    function isListener(bytes4 memoSig, address listener) external returns (bool);

    /**
     * @notice Process a memo and send it to the registered listeners.
     * @param memoData    The packed bytes to be used to call each listener.
     * @dev This function reverts if the caller is not a registered source.
     */
    function processMemo(bytes calldata memoData) external;

    /**
     * @notice Register a source so that it can send memos.
     * @param source   The address of the source.
     * @dev This function reverts if the caller is not the admin.
     */
    function registerSource(address source) external;

    /**
     * @notice DeRegister a source so that it cannot send memos.
     * @param source   The address of the source.
     * @dev This function reverts if the caller is not the admin.
     */
    function deRegisterSource(address source) external;

    /**
     * @notice Register a listener so that it can receive memos.
     * @param memoSig  The function signature of the memo that the listener wants to receive.
     * @param listener The address of the listener.
     * @dev This function reverts if the caller is not the admin.
     */
    function registerListener(bytes4 memoSig, address listener) external;

    /**
     * @notice DeRegister a listener so that it can receive memos.
     * @param memoSig  The function signature of the memo that the listener no longer wants to receive.
     * @param listener The address of the listener.
     * @dev This function reverts if the caller is not the admin.
     */
    function deRegisterListener(bytes4 memoSig, address listener) external;
}
