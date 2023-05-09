// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "src/interfaces/IVotingEscrow.sol";
import "src/interfaces/IFluxToken.sol";
import "src/interfaces/IRewardsDistributor.sol";
import "src/interfaces/aura/IRewardPool4626.sol";
import "src/interfaces/aura/IRewardStaking.sol";
import "src/interfaces/aura/MockCurveGauge.sol";
import "src/libraries/Base64.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "openzeppelin-contracts/contracts/governance/utils/IVotes.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title Voting Escrow
/// @notice veALCX implementation that escrows ERC-20 tokens in the form of an ERC-721 token
/// @notice Votes have a weight depending on time, so that users are committed to the future of (whatever they are voting for)
/// @dev Vote weight decays linearly over time. Lock time cannot be more than `MAXTIME` (1 year).
contract VotingEscrow is IERC721, IERC721Metadata, IVotes {
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

    /* We cannot really do block numbers per se b/c slope is per time, not per block
     * and per block could be fairly bad b/c Ethereum changes blocktimes.
     * What we can do is to extrapolate ***At functions */

    /// @notice A checkpoint for marking delegated tokenIds from a given timestamp
    struct Checkpoint {
        uint256 timestamp;
        uint256[] tokenIds;
    }

    string public constant name = "veALCX";
    string public constant symbol = "veALCX";
    string public constant version = "1.0.0";
    uint8 public constant decimals = 18;
    uint256 public constant BPS = 10000;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @dev ERC165 interface ID of ERC165
    bytes4 internal constant ERC165_INTERFACE_ID = 0x01ffc9a7;

    /// @dev ERC165 interface ID of ERC721
    bytes4 internal constant ERC721_INTERFACE_ID = 0x80ac58cd;

    /// @dev ERC165 interface ID of ERC721Metadata
    bytes4 internal constant ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;

    uint256 public constant EPOCH = 2 weeks;
    uint256 public constant MAX_DELEGATES = 1024; // avoid too much gas

    uint256 internal constant WEEK = 1 weeks;
    uint256 internal constant MAXTIME = 365 days;
    uint256 internal constant MULTIPLIER = 26 ether;

    int256 internal constant iMAXTIME = 365 days;
    int256 internal constant iMULTIPLIER = 26 ether;

    /// @dev Current count of token
    uint256 internal tokenId;

    address public ALCX;
    address public FLUX;
    address public BPT;
    address public rewardPool; // destination for BPT
    address public admin; // the timelock executor
    address public pendingAdmin; // the timelock executor
    address public voter;
    address public distributor;

    uint256 public supply;
    uint256 public claimFeeBps = 5000; // Fee for claiming early in bps
    uint256 public fluxMultiplier;
    uint256 public fluxPerVeALCX;
    uint256 public epoch;

    mapping(uint256 => uint256) public unclaimedFlux; // tokenId => amount of unclaimed flux
    mapping(uint256 => LockedBalance) public locked;
    mapping(uint256 => uint256) public ownershipChange;
    mapping(uint256 => Point) public pointHistory; // epoch -> unsigned point
    mapping(uint256 => Point[1000000000]) public userPointHistory; // user -> Point[userEpoch]
    mapping(uint256 => uint256) public userFirstEpoch; // user -> epoch
    mapping(uint256 => uint256) public userPointEpoch;
    mapping(uint256 => int256) public slopeChanges; // time -> signed slope change
    mapping(uint256 => uint256) public attachments;
    mapping(uint256 => bool) public voted;

    /// @dev Mapping from token ID to the address that owns it.
    mapping(uint256 => address) internal idToOwner;

    /// @dev Mapping from token ID to approved address.
    mapping(uint256 => address) internal idToApprovals;

    /// @dev Mapping from owner address to count of his tokens.
    mapping(address => uint256) internal ownerToTokenCount;

    /// @dev Mapping from owner address to mapping of index to tokenIds
    mapping(address => mapping(uint256 => uint256)) internal ownerToTokenIdList;

    /// @dev Mapping from token ID to index of owner
    mapping(uint256 => uint256) internal tokenToOwnerIndex;

    /// @dev Mapping from owner address to mapping of operator addresses.
    mapping(address => mapping(address => bool)) internal ownerToOperators;

    /// @dev Mapping of interface id to bool about whether or not it's supported
    mapping(bytes4 => bool) internal supportedInterfaces;

    /// @notice A record of each accounts delegate
    mapping(address => address) private _delegates;

    /// @notice A record of delegated token checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

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

    /// @dev reentrancy guard
    uint8 internal constant NOT_ENTERED = 1;
    uint8 internal constant ENTERED = 2;
    uint8 internal ENTERED_STATE = 1;
    modifier nonreentrant() {
        require(ENTERED_STATE == NOT_ENTERED);
        ENTERED_STATE = ENTERED;
        _;
        ENTERED_STATE = NOT_ENTERED;
    }

    /**
     * @notice Contract constructor
     * @param _bpt `BPT` token address
     * @param _alcx `ALCX` token address
     * @param _flux `FLUX` token address
     */
    constructor(address _bpt, address _alcx, address _flux, address _rewardPool) {
        BPT = _bpt;
        ALCX = _alcx;
        FLUX = _flux;
        rewardPool = _rewardPool;
        voter = msg.sender;
        admin = msg.sender;
        distributor = msg.sender;
        fluxMultiplier = 10; // 10 bps = 0.1%
        fluxPerVeALCX = 1e18; // determine initial value

        pointHistory[0].blk = block.number;
        pointHistory[0].ts = block.timestamp;

        supportedInterfaces[ERC165_INTERFACE_ID] = true;
        supportedInterfaces[ERC721_INTERFACE_ID] = true;
        supportedInterfaces[ERC721_METADATA_INTERFACE_ID] = true;
    }

    /*
        View functions
    */

    /**
     * @notice Interface identification is specified in ERC-165.
     * @param _interfaceID Id of the interface
     * @return bool Boolean result of provided interface
     */
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

    /**
     * @notice Get the most recently recorded rate of voting power decrease for `_tokenId`
     * @param _tokenId ID of the token
     * @return int256 Value of the slope
     */
    function getLastUserSlope(uint256 _tokenId) external view returns (int256) {
        uint256 userEpoch = userPointEpoch[_tokenId];
        return userPointHistory[_tokenId][userEpoch].slope;
    }

    /**
     * @notice Get the timestamp for checkpoint `_idx` for `_tokenId`
     * @param _tokenId ID of the token
     * @param _idx User epoch number
     * @return Epoch time of the checkpoint
     */
    function userPointHistoryTimestamp(uint256 _tokenId, uint256 _idx) external view returns (uint256) {
        return userPointHistory[_tokenId][_idx].ts;
    }

    /**
     * @notice Get the timestamp for checkpoint `_idx`
     * @param _idx User epoch number
     * @return Epoch time of the checkpoint
     */
    function pointHistoryTimestamp(uint256 _idx) external view returns (uint256) {
        return pointHistory[_idx].ts;
    }

    /**
     * @notice Get timestamp when `_tokenId`'s lock finishes
     * @param _tokenId ID of the token
     * @return Epoch time of the lock end
     */
    function lockEnd(uint256 _tokenId) external view returns (uint256) {
        return locked[_tokenId].end;
    }

    /**
     * @notice Get amount locked for `_tokenId`
     * @param _tokenId ID of the token
     * @return Amount locked
     */
    function lockedAmount(uint256 _tokenId) external view returns (uint256) {
        return uint256(locked[_tokenId].amount);
    }

    /**
     * @notice Get timestamp when `_tokenId`'s cooldown finishes
     * @param _tokenId ID of the token
     * @return Epoch time of the cooldown end
     */
    function cooldownEnd(uint256 _tokenId) external view returns (uint256) {
        return locked[_tokenId].cooldown;
    }

    /**
     * @notice Returns the number of tokens owned by `_owner`.
     * @param _owner Address for whom to query the balance.
     * @dev Throws if `_owner` is the zero address. tokens assigned to the zero address are considered invalid.
     */
    function balanceOf(address _owner) external view returns (uint256) {
        return _balance(_owner);
    }

    /**
     * @notice Returns the address of the owner of the token.
     * @param _tokenId ID of the token.
     */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        return idToOwner[_tokenId];
    }

    /**
     * @notice Get the approved address for a single token.
     * @param _tokenId ID of the token to query the approval of.
     */
    function getApproved(uint256 _tokenId) external view returns (address) {
        return idToApprovals[_tokenId];
    }

    /**
     * @notice Checks if `_operator` is an approved operator for `_owner`.
     * @param _owner The address that owns the tokens.
     * @param _operator The address that acts on behalf of the owner.
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return (ownerToOperators[_owner])[_operator];
    }

    /**
     * @notice  Get token by index
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _tokenIndex) external view returns (uint256) {
        return ownerToTokenIdList[_owner][_tokenIndex];
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool) {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    /**
     * @notice Overrides the standard `Comp.sol` delegates mapping to return
     * the delegator's own address if they haven't delegated.
     * This avoids having to delegate to oneself.
     */
    function delegates(address delegator) public view returns (address) {
        address current = _delegates[delegator];
        return current == address(0) ? delegator : current;
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }
        uint256[] storage _tokenIds = checkpoints[account][nCheckpoints - 1].tokenIds;
        uint256 votes = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tId = _tokenIds[i];
            votes = votes + _balanceOfToken(tId, block.timestamp);
        }
        return votes;
    }

    function getPastVotesIndex(address account, uint256 timestamp) public view returns (uint32) {
        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // If the most recent checkpoint is before the requested timestamp, return it's index
        if (checkpoints[account][nCheckpoints - 1].timestamp <= timestamp) {
            return (nCheckpoints - 1);
        }

        // If the oldest checkpoint is after the requested timestamp, return 0
        if (checkpoints[account][0].timestamp > timestamp) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;

        // Binary search to find the index of the checkpoint that is the closest to the requested timestamp
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint storage cp = checkpoints[account][center];
            if (cp.timestamp == timestamp) {
                return center;
            } else if (cp.timestamp < timestamp) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }

        // Closest index to the requested timestamp
        return lower;
    }

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past `timestamp`.
     */
    function getPastVotes(address account, uint256 timestamp) public view returns (uint256) {
        uint32 _checkIndex = getPastVotesIndex(account, timestamp);
        uint256 votes = 0;

        // If the requested timestamp is before the first checkpoint, voting power was 0 at that time
        if (timestamp < checkpoints[account][_checkIndex].timestamp) {
            return votes;
        }

        // Sum votes
        uint256[] storage _tokenIds = checkpoints[account][_checkIndex].tokenIds;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tId = _tokenIds[i];
            // Use the provided input timestamp here to get the right decay
            votes = votes + _balanceOfToken(tId, timestamp);
        }
        return votes;
    }

    function getPastTotalSupply(uint256 timestamp) external view returns (uint256) {
        return totalSupplyAtT(timestamp);
    }

    /**
     * @notice Amount of FLUX required to ragequit for a given token
     * @param _tokenId ID of token to ragequit
     */
    function amountToRagequit(uint256 _tokenId) public view returns (uint256) {
        return _balanceOfToken(_tokenId, block.timestamp) * fluxPerVeALCX;
    }

    /**
     * @notice Returns current token URI metadata
     * @param _tokenId ID of the token to fetch URI for.
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        require(idToOwner[_tokenId] != address(0), "Query for nonexistent token");
        LockedBalance memory _locked = locked[_tokenId];
        return
            _tokenURI(
                _tokenId,
                _balanceOfToken(_tokenId, block.timestamp),
                _locked.end,
                uint256(int256(_locked.amount))
            );
    }

    function balanceOfToken(uint256 _tokenId) external view returns (uint256) {
        if (ownershipChange[_tokenId] == block.number) return 0;
        return _balanceOfToken(_tokenId, block.timestamp);
    }

    function balanceOfTokenAt(uint256 _tokenId, uint256 _time) external view returns (uint256) {
        return _balanceOfToken(_tokenId, _time);
    }

    /**
     * @notice Amount of flux claimable at current epoch
     * @param _tokenId ID of the token
     * @return uint256 Amount of claimable flux for the current epoch
     */
    function claimableFlux(uint256 _tokenId) public view returns (uint256) {
        uint256 votingPower = _balanceOfToken(_tokenId, block.timestamp);
        return votingPower * fluxMultiplier;
    }

    function balanceOfAtToken(uint256 _tokenId, uint256 _block) external view returns (uint256) {
        return _balanceOfAtToken(_tokenId, _block);
    }

    /**
     * @notice Calculate total voting power
     * @param t Timestamp provided
     * @return Total voting power
     * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     */
    function totalSupplyAtT(uint256 t) public view returns (uint256) {
        uint256 _epoch = epoch;
        Point memory lastPoint = pointHistory[_epoch];
        return _supplyAt(lastPoint, t);
    }

    /**
     * @notice Calculate total voting power
     * @return Total voting power
     * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     */
    function totalSupply() external view returns (uint256) {
        return totalSupplyAtT(block.timestamp);
    }

    /**
     * @notice Calculate total voting power at some point in the past
     * @param _block Block to calculate the total voting power at
     * @return Total voting power at `_block`
     */
    function totalSupplyAt(uint256 _block) external view returns (uint256) {
        require(_block <= block.number);
        uint256 _epoch = epoch;
        uint256 targetEpoch = _findBlockEpoch(_block, _epoch);

        Point memory point = pointHistory[targetEpoch];
        uint256 dt = 0;
        if (targetEpoch < _epoch) {
            Point memory pointNext = pointHistory[targetEpoch + 1];
            if (point.blk != pointNext.blk) {
                dt = ((_block - point.blk) * (pointNext.ts - point.ts)) / (pointNext.blk - point.blk);
            }
        } else {
            if (point.blk != block.number) {
                dt = ((_block - point.blk) * (block.timestamp - point.ts)) / (block.number - point.blk);
            }
        }
        // Now dt contains info on how far are we beyond point
        return _supplyAt(point, point.ts + dt);
    }

    /* 
        External Functions 
    */

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
    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        _transferFrom(_from, _to, _tokenId, msg.sender);
    }

    /**
     * @notice Transfers the ownership of an token from one address to another address.
     * @param _from The current owner of the token.
     * @param _to The new owner.
     * @param _tokenId ID of the token to transfer.
     * @param _data Additional data with no specified format, sent in call to `_to`.
     * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the
     *      approved address for this token.
     *      Throws if `_from` is not the current owner.
     *      Throws if `_to` is the zero address.
     *      Throws if `_tokenId` is not a valid token.
     *      If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
     *      the return value is not `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public {
        _transferFrom(_from, _to, _tokenId, msg.sender);
        if (_isContract(_to)) {
            // Throws if transfer destination is a contract which does not implement 'onERC721Received'
            try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 response) {
                if (response != IERC721Receiver(_to).onERC721Received.selector) {
                    revert("ERC721: ERC721Receiver rejected tokens");
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /**
     * @notice Transfers the ownership of an token from one address to another address.
     * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the
     *      approved address for this token.
     *      Throws if `_from` is not the current owner.
     *      Throws if `_to` is the zero address.
     *      Throws if `_tokenId` is not a valid token.
     *      If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
     *      the return value is not `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     * @param _from The current owner of the token.
     * @param _to The new owner.
     * @param _tokenId ID of the token to transfer.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
     * @notice Set or reaffirm the approved address for an token. The zero address indicates there is no approved address.
     * @dev Throws unless `msg.sender` is the current token owner, or an authorized operator of the current owner.
     *      Throws if `_tokenId` is not a valid token. (NOTE: This is not written the EIP)
     *      Throws if `_approved` is the current owner. (NOTE: This is not written the EIP)
     * @param _approved Address to be approved for the given token ID.
     * @param _tokenId ID of the token to be approved.
     */
    function approve(address _approved, uint256 _tokenId) public {
        address owner = idToOwner[_tokenId];
        // Throws if `_tokenId` is not a valid token
        require(owner != address(0));
        // Throws if `_approved` is the current owner
        require(_approved != owner, "Approved is already owner");
        // Check requirements
        bool senderIsOwner = (idToOwner[_tokenId] == msg.sender);
        bool senderIsApprovedForAll = (ownerToOperators[owner])[msg.sender];
        require(senderIsOwner || senderIsApprovedForAll);
        // Set the approval
        idToApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    /**
     * @notice Enables or disables approval for a third party ("operator") to manage all of `msg.sender`'s assets.
     * @notice This works even if sender doesn't own any tokens at the time.
     * @param _operator Address to add to the set of authorized operators.
     * @param _approved True if the operators is approved, false to revoke approval.
     * @dev  Throws if `_operator` is the `msg.sender`. (This is not written the EIP)
     * @dev emits the ApprovalForAll event.
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        // Throws if `_operator` is the `msg.sender`
        require(_operator != msg.sender);
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        if (delegatee == address(0)) delegatee = msg.sender;
        return _delegate(msg.sender, delegatee);
    }

    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), block.chainid, address(this))
        );
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "VotingEscrow::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "VotingEscrow::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "VotingEscrow::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    function setVoter(address _voter) external {
        require(msg.sender == voter, "not voter");
        // require(msg.sender == admin, "not admin");
        voter = _voter;
    }

    function setRewardsDistributor(address _distributor) external {
        require(msg.sender == distributor, "not distributor");
        distributor = _distributor;
    }

    function voting(uint256 _tokenId) external {
        require(msg.sender == voter);
        voted[_tokenId] = true;
    }

    function abstain(uint256 _tokenId) external {
        require(msg.sender == voter);
        voted[_tokenId] = false;
    }

    function attach(uint256 _tokenId) external {
        require(msg.sender == voter);
        attachments[_tokenId] = attachments[_tokenId] + 1;
    }

    function detach(uint256 _tokenId) external {
        require(msg.sender == voter);
        attachments[_tokenId] = attachments[_tokenId] - 1;
    }

    function setfluxMultiplier(uint256 _fluxMultiplier) external {
        require(msg.sender == admin, "not admin");
        fluxMultiplier = _fluxMultiplier;
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "not admin");
        pendingAdmin = _admin;
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "not pending admin");
        admin = pendingAdmin;
    }

    function setfluxPerVeALCX(uint256 _fluxPerVeALCX) external {
        require(msg.sender == admin, "not admin");
        fluxPerVeALCX = _fluxPerVeALCX;
    }

    function setClaimFee(uint256 _claimFeeBps) external {
        require(msg.sender == admin, "not admin");
        claimFeeBps = _claimFeeBps;
    }

    function merge(uint256 _from, uint256 _to) external {
        require(attachments[_from] == 0 && !voted[_from], "attached");
        require(_from != _to, "must be different tokens");
        require(_isApprovedOrOwner(msg.sender, _from));
        require(_isApprovedOrOwner(msg.sender, _to));

        LockedBalance memory _locked0 = locked[_from];
        LockedBalance memory _locked1 = locked[_to];

        // Cannot merge if cooldown is active or lock is expired
        require(_locked0.cooldown == 0, "Cannot merge when cooldown period in progress");
        require(_locked1.cooldown == 0, "Cannot merge when cooldown period in progress");
        require(_locked0.end > block.timestamp, "Cannot merge when lock expired");
        require(_locked1.end > block.timestamp, "Cannot merge when lock expired");

        uint256 value0 = uint256(_locked0.amount);

        // If max lock is enabled retain the max lock
        _locked1.maxLockEnabled = _locked0.maxLockEnabled ? _locked0.maxLockEnabled : _locked1.maxLockEnabled;

        // If max lock is enabled end is the max lock time, otherwise it is the greater of the two end times
        uint256 end = _locked1.maxLockEnabled
            ? ((block.timestamp + MAXTIME) / WEEK) * WEEK
            : _locked0.end >= _locked1.end
            ? _locked0.end
            : _locked1.end;

        locked[_from] = LockedBalance(0, 0, false, 0);
        _checkpoint(_from, _locked0, LockedBalance(0, 0, false, 0));
        _burn(_from);
        _depositFor(_to, value0, end, _locked1.maxLockEnabled, _locked1, DepositType.MERGE_TYPE);
    }

    /**
     * @notice Record global data to checkpoint
     */
    function checkpoint() external {
        _checkpoint(0, LockedBalance(0, 0, false, 0), LockedBalance(0, 0, false, 0));
    }

    /**
     * @notice Deposit `_value` tokens for `_tokenId` and add to the lock
     * @param _tokenId ID of the token to deposit for
     * @param _value Amount to add to user's lock
     * @dev Anyone (even a smart contract) can deposit for someone else, but
     *      cannot extend their locktime and deposit for a brand new user
     */
    function depositFor(uint256 _tokenId, uint256 _value) external nonreentrant {
        LockedBalance memory _locked = locked[_tokenId];

        require(_value > 0); // dev: need non-zero value
        require(_locked.amount > 0, "No existing lock found");
        require(_locked.end > block.timestamp, "Cannot add to expired lock. Withdraw");
        _depositFor(_tokenId, _value, 0, _locked.maxLockEnabled, _locked, DepositType.DEPOSIT_FOR_TYPE);
    }

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
        bool _maxLockEnabled,
        address _to
    ) external nonreentrant returns (uint256) {
        return _createLock(_value, _lockDuration, _maxLockEnabled, _to);
    }

    /**
     * @notice Deposit `_value` tokens for `msg.sender` and lock for `_lockDuration`
     * @param _value Amount to deposit
     * @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
     * @param _maxLockEnabled Is max lock enabled
     */
    function createLock(
        uint256 _value,
        uint256 _lockDuration,
        bool _maxLockEnabled
    ) external nonreentrant returns (uint256) {
        return _createLock(_value, _lockDuration, _maxLockEnabled, msg.sender);
    }

    /**
     * @notice Deposit `_value` additional tokens for `_tokenId` without modifying the unlock time
     * @param _value Amount of tokens to deposit and add to the lock
     */
    function increaseAmount(uint256 _tokenId, uint256 _value) external nonreentrant {
        require(_isApprovedOrOwner(msg.sender, _tokenId));

        LockedBalance memory _locked = locked[_tokenId];

        require(_value > 0); // dev: need non-zero value
        require(_locked.amount > 0, "No existing lock found");
        require(_locked.end > block.timestamp, "Cannot add to expired lock. Withdraw");

        _depositFor(_tokenId, _value, 0, _locked.maxLockEnabled, _locked, DepositType.INCREASE_LOCK_AMOUNT);
    }

    /**
     * @notice Extend the unlock time for `_tokenId`
     * @param _lockDuration New number of seconds until tokens unlock
     * @param _maxLockEnabled Is max lock being enabled
     */
    function updateUnlockTime(uint256 _tokenId, uint256 _lockDuration, bool _maxLockEnabled) external nonreentrant {
        require(_isApprovedOrOwner(msg.sender, _tokenId));

        LockedBalance memory _locked = locked[_tokenId];

        // If max lock is enabled set to max time
        // If max lock is being disabled start decay from max time
        // If max lock is disabled and not being enabled, add unlock time to current end
        uint256 unlockTime = _maxLockEnabled ? ((block.timestamp + MAXTIME) / WEEK) * WEEK : _locked.maxLockEnabled
            ? ((block.timestamp + MAXTIME) / WEEK) * WEEK
            : ((block.timestamp + _lockDuration) / WEEK) * WEEK;

        require(_locked.end > block.timestamp, "Lock expired");
        require(_locked.amount > 0, "Nothing is locked");
        require(unlockTime >= _locked.end, "Can only increase lock duration");
        require(unlockTime <= block.timestamp + MAXTIME, "Voting lock can be 1 year max");

        _depositFor(_tokenId, 0, unlockTime, _maxLockEnabled, _locked, DepositType.INCREASE_UNLOCK_TIME);
    }

    /**
     * @notice Withdraw all tokens for `_tokenId`
     * @dev Only possible if the lock has expired
     */
    function withdraw(uint256 _tokenId) public nonreentrant {
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        require(attachments[_tokenId] == 0 && !voted[_tokenId], "attached");

        LockedBalance memory _locked = locked[_tokenId];

        require(_locked.cooldown > 0, "Cooldown period has not started");
        require(block.timestamp >= _locked.cooldown, "Cooldown period in progress");

        uint256 value = uint256(int256(_locked.amount));

        locked[_tokenId] = LockedBalance(0, 0, false, 0);
        uint256 supplyBefore = supply;
        supply = supplyBefore - value;

        // oldLocked can have either expired <= timestamp or zero end
        // _locked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(_tokenId, _locked, LockedBalance(0, 0, false, 0));

        // Withdraws BPT from reward pool
        require(_withdrawFromRewardPool(value));

        require(IERC20(BPT).transfer(ownerOf(_tokenId), value));

        // Claim any unclaimed ALCX rewards and FLUX
        IRewardsDistributor(distributor).claim(_tokenId, false);
        _claimFlux(_tokenId, unclaimedFlux[_tokenId]);

        // Burn the token
        _burn(_tokenId);

        emit Withdraw(msg.sender, _tokenId, value, block.timestamp);
        emit Supply(supplyBefore, supplyBefore - value);
    }

    /**
     * @notice Accrue unclaimed flux for a given veALCX
     * @param _tokenId ID of the token flux is being accrued to
     * @param _amount Amount of flux being accrued
     */
    function accrueFlux(uint256 _tokenId, uint256 _amount) external {
        require(msg.sender == voter, "not voter");
        unclaimedFlux[_tokenId] += _amount;
    }

    /**
     * @notice Update unclaimed flux balance for a given veALCX
     * @param _tokenId ID of the token flux is being updated for
     * @param _amount Amount of flux being used
     */
    function updateFlux(uint256 _tokenId, uint256 _amount) external {
        require(msg.sender == voter, "not voter");
        require(_amount <= unclaimedFlux[_tokenId], "not enough flux");
        unclaimedFlux[_tokenId] -= _amount;
    }

    /**
     * @notice Claim unclaimed flux for a given veALCX
     * @param _tokenId ID of the token flux is being accrued to
     * @param _amount Amount of flux being claimed
     * @dev flux can only be claimed after accrual
     */
    function claimFlux(uint256 _tokenId, uint256 _amount) external {
        _claimFlux(_tokenId, _amount);
    }

    /**
     * @notice Starts the cooldown for `_tokenId`
     * @param _tokenId ID of the token to start cooldown for
     * @dev If lock is not expired cooldown can only be started by burning FLUX
     */
    function startCooldown(uint256 _tokenId) external {
        require(_isApprovedOrOwner(msg.sender, _tokenId));

        LockedBalance memory _locked = locked[_tokenId];

        // Can only start cooldown period once
        require(_locked.cooldown == 0, "Cooldown period in progress");

        // Can only start cooldown with max lock disabled
        require(_locked.maxLockEnabled == false, "Max lock must be disabled");

        locked[_tokenId].cooldown = block.timestamp + WEEK;

        // If lock is not expired, cooldown can only be started by burning FLUX
        if (block.timestamp < _locked.end) {
            // Amount of FLUX required to ragequit
            uint256 fluxToRagequit = amountToRagequit(_tokenId);

            require(IFluxToken(FLUX).balanceOf(msg.sender) >= fluxToRagequit, "insufficient FLUX balance");

            locked[_tokenId].end = 0;

            IFluxToken(FLUX).burnFrom(msg.sender, fluxToRagequit);

            emit Ragequit(msg.sender, _tokenId, block.timestamp);
        }

        emit CooldownStarted(msg.sender, _tokenId, _locked.cooldown);
    }

    /**
     * @notice Deposit amount into rewardPool
     * @dev Can only be called by governance
     */
    function depositIntoRewardPool(uint256 _amount) external {
        require(msg.sender == admin, "not admin");
        _depositIntoRewardPool(_amount);
    }

    /**
     * @notice Withdraw amount from rewardPool
     * @dev Can only be called by governance
     */
    function withdrawFromRewardPool(uint256 _amount) external {
        require(msg.sender == admin, "not admin");
        _withdrawFromRewardPool(_amount);
    }

    /**
     * @notice Update the address of the rewardPool
     */
    function updateRewardPool(address _newRewardPool) external {
        require(msg.sender == admin, "not admin");
        rewardPool = _newRewardPool;
    }

    /**
     * @notice Claim rewards from the rewardPool
     */
    function claimRewardPoolRewards() external {
        require(msg.sender == admin, "not admin");
        // TODO: update to IRewardStaking(rewardPool).getReward(address(this), false); when Aura pool is live
        // TODO: set a destination address for rewards claimed to be sent
        MockCurveGauge(rewardPool).claim_rewards();
    }

    /*
        Internal functions
    */

    /**
     * @notice Returns the number of tokens owned by `_owner`.
     * @param _owner Address for whom to query the balance.
     * @dev Throws if `_owner` is the zero address. tokens assigned to the zero address are considered invalid.
     */
    function _balance(address _owner) internal view returns (uint256) {
        return ownerToTokenCount[_owner];
    }

    function _claimFlux(uint256 _tokenId, uint256 _amount) internal {
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        require(unclaimedFlux[_tokenId] >= _amount, "amount greater than unclaimed balance");

        unclaimedFlux[_tokenId] -= _amount;

        // FLUX is minted to the veALCX owner's address
        IFluxToken(FLUX).mint(ownerOf(_tokenId), _amount);
    }

    /**
     * @notice Returns whether the given spender can transfer a given token ID
     * @param _spender address of the spender to query
     * @param _tokenId ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID, is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = idToOwner[_tokenId];
        bool spenderIsOwner = owner == _spender;
        bool spenderIsApproved = _spender == idToApprovals[_tokenId];
        bool spenderIsApprovedForAll = (ownerToOperators[owner])[_spender];
        return spenderIsOwner || spenderIsApproved || spenderIsApprovedForAll;
    }

    /**
     * @notice Add a token to an index mapping to a given address
     * @param _to address of the receiver
     * @param _tokenId ID of the token to be added
     */
    function _addTokenToOwnerList(address _to, uint256 _tokenId) internal {
        uint256 currentCount = _balance(_to);

        ownerToTokenIdList[_to][currentCount] = _tokenId;
        tokenToOwnerIndex[_tokenId] = currentCount;
    }

    /**
     * @notice Remove a token from an index mapping to a given address
     * @param _from address of the sender
     * @param _tokenId ID of the token to be removed
     */
    function _removeTokenFromOwnerList(address _from, uint256 _tokenId) internal {
        // Delete
        uint256 currentCount = _balance(_from) - 1;
        uint256 currentIndex = tokenToOwnerIndex[_tokenId];

        if (currentCount == currentIndex) {
            // update ownerToTokenIdList
            ownerToTokenIdList[_from][currentCount] = 0;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[_tokenId] = 0;
        } else {
            uint256 lastTokenId = ownerToTokenIdList[_from][currentCount];

            // Add
            // update ownerToTokenIdList
            ownerToTokenIdList[_from][currentIndex] = lastTokenId;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[lastTokenId] = currentIndex;

            // Delete
            // update ownerToTokenIdList
            ownerToTokenIdList[_from][currentCount] = 0;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[_tokenId] = 0;
        }
    }

    /**
     * @notice Add a token to a given address
     * @dev Throws if `_tokenId` is owned by someone.
     */
    function _addTokenTo(address _to, uint256 _tokenId) internal {
        // Throws if `_tokenId` is owned by someone
        require(idToOwner[_tokenId] == address(0));
        // Change the owner
        idToOwner[_tokenId] = _to;
        // Update owner token index tracking
        _addTokenToOwnerList(_to, _tokenId);
        // Change count tracking
        ownerToTokenCount[_to] += 1;
    }

    /**
     * @notice Remove a token from a given address
     * @dev Throws if `_from` is not the current owner.
     */
    function _removeTokenFrom(address _from, uint256 _tokenId) internal {
        // Throws if `_from` is not the current owner
        require(idToOwner[_tokenId] == _from);
        // Change the owner
        idToOwner[_tokenId] = address(0);
        // Update owner token index tracking
        _removeTokenFromOwnerList(_from, _tokenId);
        // Change count tracking
        ownerToTokenCount[_from] -= 1;
    }

    /**
     * @notice Clear an approval of a given address
     * @dev Throws if `_owner` is not the current owner.
     */
    function _clearApproval(address _owner, uint256 _tokenId) internal {
        // Throws if `_owner` is not the current owner
        require(idToOwner[_tokenId] == _owner);
        if (idToApprovals[_tokenId] != address(0)) {
            // Reset approvals
            idToApprovals[_tokenId] = address(0);
        }
    }

    /**
     * @notice Exeute transfer of a token.
     * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
     *      address for this token. (NOTE: `msg.sender` not allowed in internal function so pass `_sender`.)
     *      Throws if `_to` is the zero address.
     *      Throws if `_from` is not the current owner.
     *      Throws if `_tokenId` is not a valid token.
     */
    function _transferFrom(address _from, address _to, uint256 _tokenId, address _sender) internal {
        require(attachments[_tokenId] == 0 && !voted[_tokenId], "attached");
        // Check requirements
        require(_isApprovedOrOwner(_sender, _tokenId));

        // Clear approval. Throws if `_from` is not the current owner
        _clearApproval(_from, _tokenId);
        // Remove token. Throws if `_tokenId` is not a valid token
        _removeTokenFrom(_from, _tokenId);
        // checkpoint for gov
        _moveTokenDelegates(delegates(_from), delegates(_to), _tokenId);
        // Add token
        _addTokenTo(_to, _tokenId);
        // Set the block of ownership transfer (for Flash token protection)
        ownershipChange[_tokenId] = block.number;
        // Log the transfer
        emit Transfer(_from, _to, _tokenId);
    }

    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @notice Function to mint tokens
     * @dev Throws if `_to` is zero address.
     *      Throws if `_tokenId` is owned by someone.
     * @param _to The address that will receive the minted tokens.
     * @param _tokenId ID of the token to mint.
     * @return bool indication if the operation was successful.
     */
    function _mint(address _to, uint256 _tokenId) internal returns (bool) {
        // Throws if `_to` is zero address
        assert(_to != address(0));
        // checkpoint for gov
        _moveTokenDelegates(address(0), delegates(_to), _tokenId);
        // Add token. Throws if `_tokenId` is owned by someone
        _addTokenTo(_to, _tokenId);
        // Mark first epoch
        userFirstEpoch[_tokenId] = epoch;
        emit Transfer(address(0), _to, _tokenId);
        return true;
    }

    function _findWhatCheckpointToWrite(address account) internal view returns (uint32) {
        uint256 _timestamp = block.timestamp;
        uint32 _nCheckPoints = numCheckpoints[account];

        // Overwrite the most recent checkpoint if it's the same as the current block timestamp.
        // Otherwise, if there are no checkpoints, or the most recent one is older than the current block timestamp,
        // return a new checkpoint index.
        if (_nCheckPoints > 0 && checkpoints[account][_nCheckPoints - 1].timestamp == _timestamp) {
            return _nCheckPoints - 1;
        } else {
            return _nCheckPoints;
        }
    }

    function _moveTokenDelegates(address src, address dst, uint256 _tokenId) internal {
        if (src != dst && _tokenId > 0) {
            // If the source is not the zero address, we decrement the number of tokenIds
            if (src != address(0)) {
                uint32 srcCheckpoints = numCheckpoints[src];
                // If there are no checkpoints there is nothing to copy
                if (srcCheckpoints > 0) {
                    // Get the old array of tokenIds
                    uint256[] memory srcTokensOld = checkpoints[src][srcCheckpoints - 1].tokenIds;
                    // Create a new array of tokenIds, leaving out the tokenId being transferred
                    uint256[] memory srcTokensNew = new uint256[](srcTokensOld.length - 1);
                    // If we are removing the only token, we can skip copying the array since it will be empty
                    if (srcTokensNew.length > 0) {
                        // Copy array of tokenIds, except _tokenId
                        // Track two indexes, one for the old array, one for the new array
                        uint256 newIndex = 0;
                        for (uint256 i = 0; i < srcTokensOld.length; i++) {
                            uint256 tId = srcTokensOld[i];
                            if (tId != _tokenId) {
                                srcTokensNew[newIndex] = tId;
                                newIndex++;
                            }
                        }
                    }

                    // Find the index of the checkpoint to create or update
                    uint32 srcIndex = _findWhatCheckpointToWrite(src);

                    // src has a new or updated checkpoint with the tokenId removed
                    checkpoints[src][srcIndex] = Checkpoint({ timestamp: block.timestamp, tokenIds: srcTokensNew });

                    // Add to numCheckpoints if the last checkpoint is different from the current block timestamp
                    if (srcCheckpoints == 0 || checkpoints[src][srcCheckpoints - 1].timestamp != block.timestamp) {
                        numCheckpoints[src] = srcCheckpoints + 1;
                    }
                }
            }

            // If the destination is not the zero address, we increment the number of tokenIds
            if (dst != address(0)) {
                uint32 dstCheckpoints = numCheckpoints[dst];
                uint256[] memory dstTokensOld = dstCheckpoints > 0
                    ? checkpoints[dst][dstCheckpoints - 1].tokenIds
                    : checkpoints[dst][0].tokenIds;
                uint256[] memory dstTokensNew = new uint256[](dstTokensOld.length + 1);

                require(dstTokensOld.length + 1 <= MAX_DELEGATES, "dst would have too many tokenIds");

                // Copy array plus _tokenId
                for (uint256 i = 0; i < dstTokensOld.length; i++) {
                    dstTokensNew[i] = dstTokensOld[i];
                }
                dstTokensNew[dstTokensNew.length - 1] = _tokenId;

                // Find the index of the checkpoint to create or update
                uint32 dstIndex = _findWhatCheckpointToWrite(dst);

                // dst has a new or updated checkpoint with the _tokenId added
                checkpoints[dst][dstIndex] = Checkpoint({ timestamp: block.timestamp, tokenIds: dstTokensNew });

                // Add to numCheckpoints if the last checkpoint is different from the current block timestamp
                if (dstCheckpoints == 0 || checkpoints[dst][dstCheckpoints - 1].timestamp != block.timestamp) {
                    numCheckpoints[dst] = dstCheckpoints + 1;
                }
            }
        }
    }

    function _moveAllDelegates(address owner, address src, address dst) internal {
        // You can only redelegate what you own
        if (src != dst) {
            if (src != address(0)) {
                uint32 srcCheckpoints = numCheckpoints[src];
                // If there are no checkpoints there is nothing to move
                if (srcCheckpoints > 0) {
                    // Get the old array of tokenIds
                    uint256[] memory srcTokensOld = checkpoints[src][srcCheckpoints - 1].tokenIds;
                    // Create a new array of tokenIds, leaving out the tokenIds owned by owner
                    uint256[] memory srcTokensNew = new uint256[](srcTokensOld.length - 1);
                    // If we are removing the only token, we can skip copying the array since it will be empty
                    if (srcTokensNew.length > 0) {
                        // Copy array of tokenIds except what owner owns
                        // Track two indexes, one for the old array, one for the new array
                        uint256 newIndex = 0;
                        for (uint256 i = 0; i < srcTokensOld.length; i++) {
                            uint256 tId = srcTokensOld[i];
                            if (idToOwner[tId] != owner) {
                                srcTokensNew[newIndex] = tId;
                                newIndex++;
                            }
                        }
                    }

                    // Find the index of the checkpoint to create or update
                    uint32 srcIndex = _findWhatCheckpointToWrite(src);

                    // src has a new or updated checkpoint with the tokenId removed
                    checkpoints[src][srcIndex] = Checkpoint({ timestamp: block.timestamp, tokenIds: srcTokensNew });

                    // Add to numCheckpoints if the last checkpoint is different from the current block timestamp
                    if (srcCheckpoints == 0 || checkpoints[src][srcCheckpoints - 1].timestamp != block.timestamp) {
                        numCheckpoints[src] = srcCheckpoints + 1;
                    }
                }
            }

            if (dst != address(0)) {
                uint32 dstCheckpoints = numCheckpoints[dst];
                uint256[] memory dstTokensOld = dstCheckpoints > 0
                    ? checkpoints[dst][dstCheckpoints - 1].tokenIds
                    : checkpoints[dst][0].tokenIds;

                uint256 ownerTokenCount = ownerToTokenCount[owner];
                require(dstTokensOld.length + ownerTokenCount <= MAX_DELEGATES, "dst would have too many tokenIds");

                // Create a new array of tokenIds, with the owner's tokens added
                uint256[] memory dstTokensNew = new uint256[](dstTokensOld.length + ownerTokenCount);

                // Copy array
                for (uint256 i = 0; i < dstTokensOld.length; i++) {
                    dstTokensNew[i] = dstTokensOld[i];
                }

                // Plus all that's owned
                for (uint256 i = 0; i < ownerTokenCount; i++) {
                    uint256 tId = ownerToTokenIdList[owner][i];
                    dstTokensNew[i] = tId;
                }

                // Find the index of the checkpoint to create or update
                uint32 dstIndex = _findWhatCheckpointToWrite(dst);

                // dst has a new or updated checkpoint with the _tokenId added
                checkpoints[dst][dstIndex] = Checkpoint({ timestamp: block.timestamp, tokenIds: dstTokensNew });

                // Add to numCheckpoints if the last checkpoint is different from the current block timestamp
                if (dstCheckpoints == 0 || checkpoints[dst][dstCheckpoints - 1].timestamp != block.timestamp) {
                    numCheckpoints[dst] = dstCheckpoints + 1;
                }
            }
        }
    }

    function _delegate(address delegator, address delegatee) internal {
        /// @notice differs from `_delegate()` in `Comp.sol` to use `delegates` override method to simulate auto-delegation
        address currentDelegate = delegates(delegator);

        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);
        _moveAllDelegates(delegator, currentDelegate, delegatee);
    }

    /**
     * @notice Record global and per-user data to checkpoint
     * @param _tokenId ID of the token. No user checkpoint if 0
     * @param oldLocked Pevious locked amount / end lock time for the user
     * @param newLocked New locked amount / end lock time for the user
     */
    function _checkpoint(uint256 _tokenId, LockedBalance memory oldLocked, LockedBalance memory newLocked) internal {
        Point memory oldPoint;
        Point memory newPoint;
        int256 oldDslope = 0;
        int256 newDslope = 0;
        uint256 _epoch = epoch;

        if (oldLocked.maxLockEnabled) oldLocked.end = ((block.timestamp + MAXTIME) / WEEK) * WEEK;
        if (newLocked.maxLockEnabled) newLocked.end = ((block.timestamp + MAXTIME) / WEEK) * WEEK;

        if (_tokenId != 0) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (oldLocked.end > block.timestamp && oldLocked.amount > 0) {
                oldPoint.slope = (oldLocked.amount * iMULTIPLIER) / iMAXTIME;
                oldPoint.bias = (oldPoint.slope * (int256(oldLocked.end - block.timestamp)));
            }

            if (newLocked.end > block.timestamp && newLocked.amount > 0) {
                newPoint.slope = (newLocked.amount * iMULTIPLIER) / iMAXTIME;
                newPoint.bias = (newPoint.slope * (int256(newLocked.end - block.timestamp)));
            }

            // Read values of scheduled changes in the slope
            // oldLocked.end can be in the past and in the future
            // newLocked.end can ONLY by in the FUTURE unless everything expired: then zeros
            oldDslope = slopeChanges[oldLocked.end];

            if (newLocked.end != 0) {
                if (newLocked.end == oldLocked.end) {
                    newDslope = oldDslope;
                } else {
                    newDslope = slopeChanges[newLocked.end];
                }
            }
        }

        Point memory lastPoint = Point({ bias: 0, slope: 0, ts: block.timestamp, blk: block.number });
        if (_epoch > 0) {
            lastPoint = pointHistory[_epoch];
        }
        uint256 lastCheckpoint = lastPoint.ts;
        // initialLastPoint is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        Point memory initialLastPoint = lastPoint;
        uint256 blockSlope = 0; // dblock/dt
        if (block.timestamp > lastPoint.ts) {
            blockSlope = (MULTIPLIER * (block.number - lastPoint.blk)) / (block.timestamp - lastPoint.ts);
        }
        // If last point is already recorded in this block, slope=0
        // We know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        {
            uint256 _time = (lastCheckpoint / WEEK) * WEEK;
            for (uint256 i = 0; i < 255; ++i) {
                // Hopefully it won't happen that this won't get used in 5 years!
                // If it does, users will be able to withdraw but vote weight will be broken
                _time += WEEK;
                int256 dSlope = 0;
                if (_time > block.timestamp) {
                    _time = block.timestamp;
                } else {
                    dSlope = slopeChanges[_time];
                }
                int256 biasCalculation = lastPoint.slope * (int256(_time - lastCheckpoint));
                // Make sure we still subtract from bias if value is negative
                biasCalculation >= 0 ? lastPoint.bias -= biasCalculation : lastPoint.bias += biasCalculation;
                lastPoint.slope += dSlope;
                if (lastPoint.bias < 0) {
                    // This can happen
                    lastPoint.bias = 0;
                }
                if (lastPoint.slope < 0) {
                    // This cannot happen - just in case
                    lastPoint.slope = 0;
                }
                lastCheckpoint = _time;
                lastPoint.ts = _time;
                lastPoint.blk = initialLastPoint.blk + (blockSlope * (_time - initialLastPoint.ts)) / MULTIPLIER;
                _epoch += 1;
                if (_time == block.timestamp) {
                    lastPoint.blk = block.number;
                    break;
                } else {
                    pointHistory[_epoch] = lastPoint;
                }
            }
        }

        epoch = _epoch;
        // Now pointHistory is filled until t=now

        if (_tokenId != 0) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            lastPoint.slope += (newPoint.slope - oldPoint.slope);
            lastPoint.bias += (newPoint.bias - oldPoint.bias);
            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
        }

        // Record the changed point into history
        pointHistory[_epoch] = lastPoint;

        if (_tokenId != 0) {
            // Schedule the slope changes (slope is going down)
            // We subtract from [newLocked.end]
            // and add to [oldLocked.end]
            if (oldLocked.end > block.timestamp) {
                // oldDslope was <something> - oldPoint.slope, so we cancel that
                oldDslope += oldPoint.slope;
                if (newLocked.end == oldLocked.end) {
                    oldDslope -= newPoint.slope; // It was a new deposit, not extension
                }
                slopeChanges[oldLocked.end] = oldDslope;
            }

            if (newLocked.end > block.timestamp) {
                if (newLocked.end > oldLocked.end) {
                    newDslope -= newPoint.slope; // oldPoint slope disappeared at this point
                    slopeChanges[newLocked.end] = newDslope;
                }
                // else: we recorded it already in oldDslope
            }
            // Handle user history
            uint256 userEpoch = userPointEpoch[_tokenId] + 1;

            userPointEpoch[_tokenId] = userEpoch;
            newPoint.ts = block.timestamp;
            newPoint.blk = block.number;
            userPointHistory[_tokenId][userEpoch] = newPoint;
        }
    }

    /**
     * @notice Deposit and lock tokens for a user
     * @param _tokenId ID of the token that holds lock
     * @param _value Amount to deposit
     * @param unlockTime New time when to unlock the tokens, or 0 if unchanged
     * @param lockedBalance Previous locked amount / timestamp
     * @param depositType The type of deposit
     */
    function _depositFor(
        uint256 _tokenId,
        uint256 _value,
        uint256 unlockTime,
        bool _maxLockEnabled,
        LockedBalance memory lockedBalance,
        DepositType depositType
    ) internal {
        LockedBalance memory _locked = lockedBalance;
        uint256 supplyBefore = supply;

        supply = supplyBefore + _value;
        LockedBalance memory oldLocked;
        (oldLocked.amount, oldLocked.end, oldLocked.maxLockEnabled) = (
            _locked.amount,
            _locked.end,
            _locked.maxLockEnabled
        );
        // Adding to existing lock, or if a lock is expired - creating a new one
        _locked.amount += int256(_value);

        _locked.maxLockEnabled = _maxLockEnabled;

        if (unlockTime != 0 || _locked.maxLockEnabled) {
            _locked.end = _locked.maxLockEnabled ? ((block.timestamp + MAXTIME) / WEEK) * WEEK : unlockTime;
        }

        locked[_tokenId] = _locked;

        // Possibilities:
        // Both oldLocked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)
        _checkpoint(_tokenId, oldLocked, _locked);

        address from = msg.sender;
        if (_value != 0 && depositType != DepositType.MERGE_TYPE) {
            require(IERC20(BPT).transferFrom(from, address(this), _value));
            // Deposits BPT into reward pool
            require(_depositIntoRewardPool(_value));
        }

        emit Deposit(from, _tokenId, _value, _locked.end, _locked.maxLockEnabled, depositType, block.timestamp);
        emit Supply(supplyBefore, supplyBefore + _value);
    }

    /**
     * @notice Deposit `_value` tokens for `_to` and lock for `_lockDuration`
     * @param _value Amount to deposit
     * @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
     * @param _to Address to deposit
     * @return uint256 tokenId of the newly created veALCX
     */
    function _createLock(
        uint256 _value,
        uint256 _lockDuration,
        bool _maxLockEnabled,
        address _to
    ) internal returns (uint256) {
        // Locktime rounded down to weeks
        uint256 unlockTime = _maxLockEnabled
            ? ((block.timestamp + MAXTIME) / WEEK) * WEEK
            : ((block.timestamp + _lockDuration) / WEEK) * WEEK;

        require(_value > 0); // dev: need non-zero value
        require(unlockTime > block.timestamp, "Can only lock until time in the future");
        require(unlockTime <= block.timestamp + MAXTIME, "Voting lock can be 1 year max");
        require(unlockTime >= block.timestamp + EPOCH, "Voting lock must be 1 epoch");

        ++tokenId;
        uint256 _tokenId = tokenId;
        _mint(_to, _tokenId);

        _depositFor(_tokenId, _value, unlockTime, _maxLockEnabled, locked[_tokenId], DepositType.CREATE_LOCK_TYPE);
        return _tokenId;
    }

    /**
     * @notice Deposit amount into rewardPool
     * @param _amount Amount to deposit
     */
    function _depositIntoRewardPool(uint256 _amount) internal returns (bool) {
        IERC20(BPT).approve(rewardPool, _amount);
        // TODO: Update to IRewardPool4626(rewardPool).deposit(_amount, address(this)); when Aura pool is live
        MockCurveGauge(rewardPool).deposit(_amount);
        return true;
    }

    /**
     * @notice Withdraw amount from rewardPool
     * @param _amount Amount to withdraw
     */
    function _withdrawFromRewardPool(uint256 _amount) internal returns (bool) {
        // TODO: Update to IRewardPool4626(rewardPool).withdraw(_amount, address(this), address(this)); when Aura pool is live
        MockCurveGauge(rewardPool).withdraw(_amount);
        return true;
    }

    // The following ERC20/minime-compatible methods are not real balanceOf and supply!
    // They measure the weights for the purpose of voting, so they don't represent
    // real coins.
    /**
     * @notice Binary search to estimate timestamp for block number
     * @param _block Block to find
     * @param maxEpoch Don't go beyond this epoch
     * @return Approximate timestamp for block
     */
    function _findBlockEpoch(uint256 _block, uint256 maxEpoch) internal view returns (uint256) {
        // Binary search
        uint256 _min = 0;
        uint256 _max = maxEpoch;
        for (uint256 i = 0; i < 128; ++i) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (pointHistory[_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    /**
     * @notice Get the current voting power for `_tokenId`
     * @param _tokenId ID of the token
     * @param _time Epoch time to return voting power at
     * @return User voting power
     * @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
     */
    function _balanceOfToken(uint256 _tokenId, uint256 _time) internal view returns (uint256) {
        uint256 _epoch = userPointEpoch[_tokenId];

        // If time is before before the first epoch or a tokens first timestamp, return 0
        if (_epoch == 0 || _time < pointHistory[userFirstEpoch[_tokenId]].ts) {
            return 0;
        } else {
            Point memory lastPoint = userPointHistory[_tokenId][_epoch];

            // If max lock is enabled bias is unchanged
            int256 biasCalculation = locked[_tokenId].maxLockEnabled
                ? int256(0)
                : lastPoint.slope * (int256(_time) - int256(lastPoint.ts));

            // Make sure we still subtract from bias if value is negative
            biasCalculation >= 0 ? lastPoint.bias -= biasCalculation : lastPoint.bias += biasCalculation;

            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }

            return uint256(lastPoint.bias);
        }
    }

    /**
     * @notice Measure voting power of `_tokenId` at block height `_block`
     * @param _tokenId ID of the token
     * @param _block Block to calculate the voting power at
     * @return Voting power
     * @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
     */
    function _balanceOfAtToken(uint256 _tokenId, uint256 _block) internal view returns (uint256) {
        // totalSupply code because Vyper cannot pass by reference yet
        require(_block <= block.number);

        // Binary search
        uint256 _min = 0;
        uint256 _max = userPointEpoch[_tokenId];
        for (uint256 i = 0; i < 128; ++i) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (userPointHistory[_tokenId][_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        Point memory upoint = userPointHistory[_tokenId][_min];

        uint256 maxEpoch = epoch;
        uint256 _epoch = _findBlockEpoch(_block, maxEpoch);
        Point memory point0 = pointHistory[_epoch];
        uint256 dBlock = 0;
        uint256 dT = 0;
        if (_epoch < maxEpoch) {
            Point memory point1 = pointHistory[_epoch + 1];
            dBlock = point1.blk - point0.blk;
            dT = point1.ts - point0.ts;
        } else {
            dBlock = block.number - point0.blk;
            dT = block.timestamp - point0.ts;
        }
        uint256 blockTime = point0.ts;
        if (dBlock != 0) {
            blockTime += (dT * (_block - point0.blk)) / dBlock;
        }

        upoint.bias -= upoint.slope * (int256(blockTime - upoint.ts));
        if (upoint.bias >= 0) {
            return uint256(upoint.bias);
        } else {
            return 0;
        }
    }

    /**
     * @notice Calculate total voting power at some point in the past
     * @param point The point (bias/slope) to start search from
     * @param t Time to calculate the total voting power at
     * @return Total voting power at that time
     */
    function _supplyAt(Point memory point, uint256 t) internal view returns (uint256) {
        Point memory lastPoint = point;

        uint256 _time = (lastPoint.ts / WEEK) * WEEK;
        for (uint256 i = 0; i < 255; ++i) {
            _time += WEEK;
            int256 dSlope = 0;
            if (_time > t) {
                _time = t;
            } else {
                dSlope = slopeChanges[_time];
            }

            int256 biasCalculation = lastPoint.slope * (int256(_time) - int256(lastPoint.ts));

            // Make sure we still subtract from bias if value is negative
            biasCalculation >= 0 ? lastPoint.bias -= biasCalculation : lastPoint.bias += biasCalculation;

            if (_time == t) {
                break;
            }
            lastPoint.slope += dSlope;
            lastPoint.ts = _time;
        }

        // Total power could be 0
        if (lastPoint.bias < 0) {
            lastPoint.bias = 0;
        }
        return uint256(lastPoint.bias);
    }

    function _tokenURI(
        uint256 _tokenId,
        uint256 _balanceOf,
        uint256 _lockedEnd,
        uint256 _value
    ) internal pure returns (string memory output) {
        output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        output = string(
            abi.encodePacked(output, "token ", toString(_tokenId), '</text><text x="10" y="40" class="base">')
        );
        output = string(
            abi.encodePacked(output, "balanceOf ", toString(_balanceOf), '</text><text x="10" y="60" class="base">')
        );
        output = string(
            abi.encodePacked(output, "locked_end ", toString(_lockedEnd), '</text><text x="10" y="80" class="base">')
        );
        output = string(abi.encodePacked(output, "value ", toString(_value), "</text></svg>"));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "lock #',
                        toString(_tokenId),
                        '", "description": "BPT locks, can be used to boost yields, capture emissions, vote on governance", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function _burn(uint256 _tokenId) internal {
        address owner = ownerOf(_tokenId);

        // Clear approval
        approve(address(0), _tokenId);
        // Checkpoint for gov
        _moveTokenDelegates(delegates(owner), address(0), _tokenId);
        // Remove token
        _removeTokenFrom(owner, _tokenId);
        emit Transfer(owner, address(0), _tokenId);
    }
}
