// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

interface IVotingEscrow {
    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_UNLOCK_TIME,
        MERGE_TYPE
    }

    /// @notice A checkpoint for marking delegated tokenIds from a given timestamp
    struct Checkpoint {
        uint256 timestamp;
        uint256[] tokenIds;
    }

    struct Point {
        int256 bias;
        int256 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    struct LockedBalance {
        uint256 amount;
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

    event AdminUpdated(address admin);
    event ClaimFeeUpdated(uint256 claimFee);
    event VoterUpdated(address voter);
    event RewardsDistributorUpdated(address distributor);
    event FluxMultiplierUpdated(uint256 fluxMultiplier);
    event FluxPerVeALCXUpdated(uint256 fluxPerVeALCX);
    event Withdraw(address indexed provider, uint256 tokenId, uint256 value, uint256 ts);
    event Supply(uint256 prevSupply, uint256 supply);
    event Ragequit(address indexed provider, uint256 tokenId, uint256 ts);
    event CooldownStarted(address indexed provider, uint256 tokenId, uint256 ts);
    event TreasuryUpdated(address indexed newTreasury);

    /**
     * @notice Get the tokenIds for a given address from the last checkpoint
     * @param _address Address of the user
     * @return Array of tokenIds
     */
    function getTokenIds(address _address) external view returns (uint256[] memory);

    /**
     * @notice  Get token by index
     * @param _owner Address of the user
     * @param _tokenIndex Index of the token
     * @return Token ID
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _tokenIndex) external view returns (uint256);

    function BPT() external view returns (address);

    function MULTIPLIER() external view returns (uint256);

    function MAXTIME() external view returns (uint256);

    function ALCX() external view returns (address);

    function distributor() external view returns (address);

    function claimFeeBps() external view returns (uint256);

    function fluxPerVeALCX() external view returns (uint256);

    function fluxMultiplier() external view returns (uint256);

    function EPOCH() external view returns (uint256);

    function epoch() external view returns (uint256);

    /**
     * @notice Set the flux multiplier value (ex: 4)
     * @param _fluxMultiplier Value to set
     * @dev Represents a multiplier of the max lock time it will take to accrue the FLUX needed to unlock early
     * @dev Example: 4x multipler with 1 year max lock will take 4 years to accrue the FLUX needed to unlock early
     */
    function setfluxMultiplier(uint256 _fluxMultiplier) external;

    /**
     * @notice Set the flux per veALCX value
     * @param _fluxPerVeALCX Value to set
     * @dev This is the amount of FLUX a veALCX holder can claim per epoch
     */
    function setfluxPerVeALCX(uint256 _fluxPerVeALCX) external;

    /**
     * @notice Set the claim fee for claiming ALCX rewards early
     * @param _claimFeeBps Basis points of the claim fee
     * @dev Example: With 5000 claim fee 100 ALCX reward will result in 50 ALCX fee
     */
    function setClaimFee(uint256 _claimFeeBps) external;

    /**
     * @notice Get timestamp when `_tokenId`'s lock finishes
     * @param tokenId ID of the token
     * @return Epoch time of the lock end
     */
    function lockEnd(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Check if token is max locked
     * @param tokenId ID of the token
     * @return True if token has max lock enabled
     */
    function isMaxLocked(uint256 tokenId) external view returns (bool);

    /**
     * @notice Get amount locked for `_tokenId`
     * @param _tokenId ID of the token
     * @return Amount locked
     */
    function lockedAmount(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Get timestamp when `_tokenId`'s cooldown finishes
     * @param tokenId ID of the token
     * @return Epoch time of the cooldown end
     */
    function cooldownEnd(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Get the point history for a given epoch
     * @param loc Epoch number
     */
    function getPointHistory(uint256 loc) external view returns (Point memory);

    /**
     * @notice Get the point history for a given user
     * @param tokenId ID of the token
     * @param loc Epoch number
     */
    function getUserPointHistory(uint256 tokenId, uint256 loc) external view returns (Point memory);

    /**
     * @notice Returns the number of tokens owned by `_owner`.
     * @param _owner Address for whom to query the balance.
     * @dev Throws if `_owner` is the zero address. tokens assigned to the zero address are considered invalid.
     */
    function balanceOf(address _owner) external view returns (uint256);

    /**
     * @notice Get the most recently recorded rate of voting power decrease for `_tokenId`
     * @param _tokenId ID of the token
     * @return int256 Value of the slope
     */
    function getLastUserSlope(uint256 _tokenId) external view returns (int256);

    /**
     * @notice Get the timestamp for checkpoint `_idx` for `_tokenId`
     * @param _tokenId ID of the token
     * @param _idx Epoch number
     * @return Epoch time of the checkpoint
     */
    function userPointHistoryTimestamp(uint256 _tokenId, uint256 _idx) external view returns (uint256);

    /**
     * @notice Get the timestamp for checkpoint `_idx`
     * @param _idx Epoch number
     * @return Epoch time of the checkpoint
     */
    function pointHistoryTimestamp(uint256 _idx) external view returns (uint256);

    function userPointEpoch(uint256 tokenId) external view returns (uint256);

    function userFirstEpoch(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Returns the address of the owner of the token.
     * @param tokenId ID of the token.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @notice Get the approved address for a single token.
     * @param _tokenId ID of the token to query the approval of.
     */
    function getApproved(uint256 _tokenId) external view returns (address);

    /**
     * @notice Checks if `_operator` is an approved operator for `_owner`.
     * @param _owner The address that owns the tokens.
     * @param _operator The address that acts on behalf of the owner.
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    /**
     * @notice Return if an address is either the owner or approved delegate for a token
     * @param _address Address to check
     * @param _tokenId ID of the token to check
     */
    function isApprovedOrOwner(address _address, uint256 _tokenId) external view returns (bool);

    /**
     * @notice Set the address of the voter contract
     * @param voter Address of the voter contract
     */
    function setVoter(address voter) external;

    /**
     * @notice Set the address of the rewards distributor contract
     * @param _distributor Address of the rewards distributor contract
     */
    function setRewardsDistributor(address _distributor) external;

    /**
     * @notice Set the address of the reward pool manager contract
     * @param _rewardPoolManager Address of the reward pool manager contract
     */
    function setRewardPoolManager(address _rewardPoolManager) external;

    /**
     * @notice Overrides the standard `Comp.sol` delegates mapping to return
     * the delegator's own address if they haven't delegated.
     * This avoids having to delegate to oneself.
     */
    function delegates(address delegator) external view returns (address);

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @notice Gets the current votes balance for `account` at a specific timestamp
     * @param account The address to get votes balance
     * @param timestamp The timestamp to get votes balance at
     * @return The number of current votes for `account`
     */
    function getPastVotesIndex(address account, uint256 timestamp) external view returns (uint32);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past `timestamp`.
     */
    function getPastVotes(address account, uint256 timestamp) external view returns (uint256);

    /**
     * @notice Get the total supply at a given timestamp
     */
    function getPastTotalSupply(uint256 timestamp) external view returns (uint256);

    /**
     * @notice Returns current token URI metadata
     * @param _tokenId ID of the token to fetch URI for.
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory);

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

    /**
     * @notice Set a token to currently be voting
     * @param tokenId ID of the token
     * @dev Can only be called by the voter contract
     */
    function voting(uint256 tokenId) external;

    /**
     * @notice Set a token to currently be abstaining
     * @param tokenId ID of the token
     * @dev Can only be called by the voter contract
     */
    function abstain(uint256 tokenId) external;

    /**
     * @notice Record global data to checkpoint
     */
    function checkpoint() external;

    /**
     * @notice Update lock end for max locked tokens
     * @param tokenId ID of the token
     *
     * @dev This ensures token will continue to accrue flux
     */
    function updateLock(uint256 tokenId) external;

    /**
     * @notice Deposit `_value` tokens for `_tokenId` and add to the lock
     * @param tokenId ID of the token to deposit for
     * @param value Amount to add to user's lock
     * @dev Anyone (even a smart contract) can deposit for someone else, but
     *      cannot extend their locktime and deposit for a brand new user
     */
    function depositFor(uint256 tokenId, uint256 value) external;

    /**
     * @notice Voting power of a given tokenId
     * @param tokenId ID of the token
     * @return uint256 Voting power of the token
     */
    function balanceOfToken(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Voting power of a given tokenId at a given time
     * @param _tokenId ID of the token
     * @param _time Timestamp to check balance at
     * @return uint256 Voting power of the token
     */
    function balanceOfTokenAt(uint256 _tokenId, uint256 _time) external view returns (uint256);

    /**
     * @notice Amount of flux claimable at current epoch
     * @param tokenId ID of the token
     * @return uint256 Amount of claimable flux for the current epoch
     * @dev flux should accrue at the ragequit amount divided by the fluxMultiplier per epoch
     */
    function claimableFlux(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Starts the cooldown for `_tokenId`
     * @param tokenId ID of the token to start cooldown for
     * @dev If lock is not expired cooldown can only be started by burning FLUX
     */
    function startCooldown(uint256 tokenId) external;

    /**
     * @notice Amount of FLUX required to ragequit for a given token
     * @param tokenId ID of token to ragequit
     * @return uint256 Amount of FLUX required to ragequit
     * @dev Amount to ragequit should be a function of the voting power
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

    /**
     * @notice Merge two veALCX tokens
     * @param _from ID of the token to merge from (will be burned)
     * @param _to ID of the token to merge into
     */
    function merge(uint256 _from, uint256 _to) external;
}
