pragma solidity 0.8.13;

interface IMemoProcessor {
    /// @dev Emitted when a memo is successfully processed.
    event MemoProcessed(bytes memoData);

    /// @dev Emitted when a source is registered.
    event SourceRegistered(address source);

    /// @dev Emitted when a source is de-registered.
    event SourceDeRegistered(address source);

    /// @dev Emitted when a listener is registered.
    event ListenerRegistered(bytes4 memoSig, address listener);

    /// @dev Emitted when a listener is de-registered.
    event ListenerDeRegistered(bytes4 memoSig, address listener);

    /// @dev Process a memo and send it to the registered listeners.
    ///
    /// @notice This function reverts if the caller is not a registered source.
    ///
    /// @param eventData    The packed bytes to be used to call each listener.
    function processMemo(bytes calldata eventData) external;

    /// @dev Register a source so that it can send memos.
    ///
    /// @notice This function reverts if the caller is not the admin.
    ///
    /// @param source   The address of the source.
    function registerSource(address source) external;

    /// @dev DeRegister a source so that it cannot send memos.
    ///
    /// @notice This function reverts if the caller is not the admin.
    ///
    /// @param source   The address of the source.
    function deRegisterSource(address source) external;

    /// @dev Register a listener so that it can receive memos.
    ///
    /// @notice This function reverts if the caller is not the admin.
    ///
    /// @param memoSig  The function signature of the memo that the listener wants to receive.
    /// @param listener The address of the listener.
    function registerListener(bytes4 memoSig, address listener) external;

    /// @dev DeRegister a listener so that it can receive memos.
    ///
    /// @notice This function reverts if the caller is not the admin.
    ///
    /// @param memoSig  The function signature of the memo that the listener no longer wants to receive.
    /// @param listener The address of the listener.
    function deRegisterListener(bytes4 memoSig, address listener) external;
}