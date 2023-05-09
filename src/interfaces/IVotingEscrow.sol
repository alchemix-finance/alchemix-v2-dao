// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

interface IVotingEscrow {
    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME,
        MERGE_TYPE
    }

    struct Point {
        int256 bias;
        int256 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    struct LockedBalance {
        int256 amount;
        uint256 end;
        bool maxLockEnabled;
        uint256 cooldown;
    }

    event Deposit(
        address indexed provider,
        uint256 tokenId,
        uint256 value,
        uint256 indexed locktime,
        bool maxLockEnabled,
        DepositType depositType,
        uint256 ts
    );
    event Withdraw(address indexed provider, uint256 tokenId, uint256 value, uint256 ts);
    event Supply(uint256 prevSupply, uint256 supply);
    event Ragequit(address indexed provider, uint256 tokenId, uint256 ts);
    event CooldownStarted(address indexed provider, uint256 tokenId, uint256 ts);

    function BPT() external view returns (address);

    function ALCX() external view returns (address);

    function claimFeeBps() external view returns (uint256);

    function EPOCH() external view returns (uint256);

    function epoch() external view returns (uint256);

    function lockEnd(uint256 tokenId) external view returns (uint256);

    function pointHistory(uint256 loc) external view returns (Point memory);

    function userPointHistory(uint256 tokenId, uint256 loc) external view returns (Point memory);

    /**
     * @notice Get the timestamp for checkpoint `_idx` for `_tokenId`
     * @param _tokenId ID of the token
     * @param _idx User epoch number
     * @return Epoch time of the checkpoint
     */
    function userPointHistoryTimestamp(uint256 _tokenId, uint256 _idx) external view returns (uint256);

    /**
     * @notice Get the timestamp for checkpoint `_idx`
     * @param _idx User epoch number
     * @return Epoch time of the checkpoint
     */
    function pointHistoryTimestamp(uint256 _idx) external view returns (uint256);

    function userPointEpoch(uint256 tokenId) external view returns (uint256);

    function userFirstEpoch(uint256 tokenId) external view returns (uint256);

    function ownerOf(uint256) external view returns (address);

    function isApprovedOrOwner(address, uint256) external view returns (bool);

    function setVoter(address voter) external;

    /**
     * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this token.
     *      Throws if `_from` is not the current owner.
     *      Throws if `_to` is the zero address.
     *      Throws if `_tokenId` is not a valid token.
     * @dev The caller is responsible to confirm that `_to` is capable of receiving tokens or else
     *        they maybe be permanently lost.
     * @param _from The current owner of the token.
     * @param _to The new owner.
     * @param _tokenId ID of the token to transfer.
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    function voting(uint256 tokenId) external;

    function abstain(uint256 tokenId) external;

    function attach(uint256 tokenId) external;

    function detach(uint256 tokenId) external;

    /**
     * @notice Record global data to checkpoint
     */
    function checkpoint() external;

    /**
     * @notice Deposit `_value` tokens for `_tokenId` and add to the lock
     * @param tokenId ID of the token to deposit for
     * @param value Amount to add to user's lock
     * @dev Anyone (even a smart contract) can deposit for someone else, but
     *      cannot extend their locktime and deposit for a brand new user
     */
    function depositFor(uint256 tokenId, uint256 value) external;

    /**
     * @notice Deposit `_value` tokens for `_to` and lock for `_lockDuration`
     * @param _value Amount to deposit
     * @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
     * @param _maxLockEnabled Is max lock enabled
     * @param _to Address to deposit
     */
    function createLockFor(
        uint256 _value,
        uint256 _lockDuration,
        address _maxLockEnabled,
        address _to
    ) external returns (uint256);

    function balanceOfToken(uint256 tokenId) external view returns (uint256);

    function balanceOfTokenAt(uint256 _tokenId, uint256 _time) external view returns (uint256);

    /**
     * @notice Amount of flux claimable at current epoch
     * @param tokenId ID of the token
     * @return uint256 Amount of claimable flux for the current epoch
     */
    function claimableFlux(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Total amount of flux accrued
     * @param tokenId ID of the token
     * @return uint256 Total amount of flux accrued
     */
    function unclaimedFlux(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Accrue unclaimed flux for a given veALCX
     * @param tokenId ID of the token flux is being accrued to
     * @param amount Amount of flux being accrued
     */
    function accrueFlux(uint256 tokenId, uint256 amount) external;

    /**
     * @notice Update unclaimed flux balance for a given veALCX
     * @param tokenId ID of the token flux is being updated for
     * @param amount Amount of flux being used
     */
    function updateFlux(uint256 tokenId, uint256 amount) external;

    /**
     * @notice Claim unclaimed flux for a given veALCX
     * @param tokenId ID of the token flux is being accrued to
     * @param amount Amount of flux being claimed
     * @dev flux can be claimed after accrual
     */
    function claimFlux(uint256 tokenId, uint256 amount) external;

    /**
     * @notice Starts the cooldown for `_tokenId`
     * @param tokenId ID of the token to start cooldown for
     * @dev If lock is not expired cooldown can only be started by burning FLUX
     */
    function startCooldown(uint256 tokenId) external;

    /**
     * @notice Amount of FLUX required to ragequit for a given token
     * @param tokenId ID of token to ragequit
     */
    function amountToRagequit(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Calculate total voting power
     * @return Total voting power
     * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Calculate total voting power
     * @param t Timestamp provided
     * @return Total voting power
     * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     */
    function totalSupplyAtT(uint256 t) external view returns (uint256);
}
