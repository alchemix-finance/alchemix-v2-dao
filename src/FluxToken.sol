// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "lib/forge-std/src/console2.sol";

import "src/interfaces/IFluxToken.sol";
import "src/interfaces/IVotingEscrow.sol";
import "src/interfaces/IAlchemechNFT.sol";
import "src/interfaces/IAlEthNFT.sol";
import "src/interfaces/IRewardsDistributor.sol";
import "src/interfaces/balancer/IVault.sol";
import "src/interfaces/balancer/IManagedPool.sol";
import "src/interfaces/balancer/IBasePool.sol";
import { WeightedMath } from "src/interfaces/balancer/WeightedMath.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title  Flux Token
 * @notice Contract for the Alchemix DAO Flux token
 */
contract FluxToken is ERC20("Flux", "FLUX"), IFluxToken {
    using SafeERC20 for ERC20;

    /// @dev The address which enables the minting of tokens.
    address public minter;
    /// @notice The address of the voter contract.
    address public voter;
    /// @notice The address of the veALCX contract.
    address public veALCX;
    /// @notice The address of the alchemechNFT contract (valued in TOKE).
    address public alchemechNFT;
    /// @notice The address of the patronNFT contract (valued in ETH).
    address public patronNFT;
    /// @notice The address of the admin and will be the timelock executor.
    address public admin;
    /// @notice The address of the pending admin.
    address public pendingAdmin;
    /// @notice The date the contract was deployed.
    uint256 public deployDate;
    /// @notice The multiplier for alchemechNFT holders (.05% ratio of FLUX for alchemechNFT holders)
    uint256 public alchemechMultiplier = 5;
    /// @notice The ratio of FLUX patron NFT holders receive (.4%)
    uint256 public bptMultiplier = 40;

    uint256 public immutable oneYear = 365 days;
    uint256 internal immutable BPS = 10_000;

    mapping(uint256 => uint256) public unclaimedFlux; // tokenId => amount of unclaimed flux
    mapping(address => mapping(uint256 => bool)) public claimed; // nft => tokenId => claimed

    constructor(address _minter) {
        require(_minter != address(0), "FluxToken: minter cannot be zero address");
        minter = _minter;
        voter = _minter;
        veALCX = _minter;
        admin = _minter;
        deployDate = block.timestamp;
    }

    /// @dev Modifier which checks that the caller has the minter role.
    modifier onlyMinter() {
        require((msg.sender == minter), "FluxToken: only minter");
        _;
    }

    /// @inheritdoc IFluxToken
    function setAdmin(address _admin) external {
        require(msg.sender == admin, "not admin");
        pendingAdmin = _admin;
    }

    /// @inheritdoc IFluxToken
    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "not pending admin");
        admin = pendingAdmin;
        emit AdminUpdated(pendingAdmin);
    }

    /// @inheritdoc IFluxToken
    function setVoter(address _voter) external {
        require(msg.sender == admin, "not admin");
        require(_voter != address(0), "FluxToken: voter cannot be zero address");
        voter = _voter;
    }

    /// @inheritdoc IFluxToken
    function setVeALCX(address _veALCX) external {
        require(msg.sender == admin, "not admin");
        require(_veALCX != address(0), "FluxToken: veALCX cannot be zero address");
        veALCX = _veALCX;
    }

    function setAlchemechNFT(address _alchemechNFT) external {
        require(msg.sender == admin, "not admin");
        require(_alchemechNFT != address(0), "FluxToken: alchemechNFT cannot be zero address");
        alchemechNFT = _alchemechNFT;
    }

    function setPatronNFT(address _patronNFT) external {
        require(msg.sender == admin, "not admin");
        require(_patronNFT != address(0), "FluxToken: patronNFT cannot be zero address");
        patronNFT = _patronNFT;
    }

    /// @inheritdoc IFluxToken
    function setNftMultiplier(uint256 _nftMultiplier) external {
        require(msg.sender == admin, "not admin");
        require(_nftMultiplier != 0, "FluxToken: nftMultiplier cannot be zero");
        require(_nftMultiplier <= BPS, "FluxToken: nftMultiplier cannot be greater than BPS");
        alchemechMultiplier = _nftMultiplier;
    }

    /// @inheritdoc IFluxToken
    function setBptMultiplier(uint256 _bptMultiplier) external {
        require(msg.sender == admin, "not admin");
        require(_bptMultiplier != 0, "FluxToken: bptMultiplier cannot be zero");
        require(_bptMultiplier <= BPS, "FluxToken: bptMultiplier cannot be greater than BPS");
        bptMultiplier = _bptMultiplier;
    }

    /// @inheritdoc IFluxToken
    function setMinter(address _minter) external onlyMinter {
        require(_minter != address(0), "FluxToken: minter cannot be zero address");
        minter = _minter;
    }

    /// @inheritdoc IFluxToken
    function mint(address _recipient, uint256 _amount) external onlyMinter {
        _mint(_recipient, _amount);
    }

    /// @inheritdoc IFluxToken
    function nftClaim(address _nft, uint256 _tokenId) external {
        // require claim to be within a year of deploy date
        require(block.timestamp < deployDate + oneYear, "claim period has passed");

        require(!claimed[_nft][_tokenId], "already claimed");

        // value of the NFT
        uint256 tokenData = 0;

        // determine which nft is being claimed
        if (_nft == alchemechNFT) {
            // require sender to be owner of the NFT
            require(IAlchemechNFT(_nft).ownerOf(_tokenId) == msg.sender, "not owner of Alchemech NFT");

            tokenData = IAlchemechNFT(_nft).tokenData(_tokenId);
        } else if (_nft == patronNFT) {
            // require sender to be owner of the NFT
            require(IAlEthNFT(_nft).ownerOf(_tokenId) == msg.sender, "not owner of Patron NFT");

            tokenData = IAlEthNFT(_nft).tokenData(_tokenId);
        } else {
            revert("invalid NFT");
        }

        // mark the token as claimed
        claimed[_nft][_tokenId] = true;

        uint256 amount = getClaimableFlux(tokenData, _nft);

        _mint(msg.sender, amount);
    }

    /// @inheritdoc IFluxToken
    function burnFrom(address _account, uint256 _amount) external {
        uint256 newAllowance = allowance(_account, msg.sender) - _amount;

        _approve(_account, msg.sender, newAllowance);
        _burn(_account, _amount);
    }

    /// @inheritdoc IFluxToken
    function getUnclaimedFlux(uint256 _tokenId) external view returns (uint256) {
        return unclaimedFlux[_tokenId];
    }

    /// @inheritdoc IFluxToken
    function mergeFlux(uint256 _fromTokenId, uint256 _toTokenId) external {
        require(msg.sender == veALCX, "not veALCX");

        unclaimedFlux[_toTokenId] += unclaimedFlux[_fromTokenId];
        unclaimedFlux[_fromTokenId] = 0;
    }

    /// @inheritdoc IFluxToken
    function accrueFlux(uint256 _tokenId) external {
        require(msg.sender == voter, "not voter");
        uint256 amount = IVotingEscrow(veALCX).claimableFlux(_tokenId);
        unclaimedFlux[_tokenId] += amount;
    }

    /// @inheritdoc IFluxToken
    function updateFlux(uint256 _tokenId, uint256 _amount) external {
        require(msg.sender == voter, "not voter");
        require(_amount <= unclaimedFlux[_tokenId], "not enough flux");
        unclaimedFlux[_tokenId] -= _amount;
    }

    /// @inheritdoc IFluxToken
    function claimFlux(uint256 _tokenId, uint256 _amount) external {
        require(unclaimedFlux[_tokenId] >= _amount, "amount greater than unclaimed balance");

        if (msg.sender != veALCX) {
            require(IVotingEscrow(veALCX).isApprovedOrOwner(msg.sender, _tokenId), "not approved");
        }

        unclaimedFlux[_tokenId] -= _amount;

        _mint(IVotingEscrow(veALCX).ownerOf(_tokenId), _amount);
    }

    // Given an amount of eth, calculate how much FLUX it would earn in a year if it were deposited into veALCX
    function getClaimableFlux(uint256 _amount, address _nft) public view returns (uint256 claimableFlux) {
        uint256 bpt = _calculateBPT(_amount);

        uint256 veMul = IVotingEscrow(veALCX).MULTIPLIER();
        uint256 veMax = IVotingEscrow(veALCX).MAXTIME();
        uint256 fluxPerVe = IVotingEscrow(veALCX).fluxPerVeALCX();
        uint256 fluxMul = IVotingEscrow(veALCX).fluxMultiplier();

        // Amount of flux earned in 1 yr from _amount assuming it was deposited for maxtime
        claimableFlux = (((bpt * veMul) / veMax) * veMax * (fluxPerVe + BPS)) / BPS / fluxMul;

        // Claimable flux for alchemechNFT is different than patronNFT
        if (_nft == alchemechNFT) {
            claimableFlux = (claimableFlux * alchemechMultiplier) / BPS;
        }
    }

    function _calculateBPT(uint256 _amount) public view returns (uint256 bptOut) {
        bptOut = _amount * bptMultiplier;
    }
}
