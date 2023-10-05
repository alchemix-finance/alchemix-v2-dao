// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "src/interfaces/IFluxToken.sol";
import "src/interfaces/IVotingEscrow.sol";
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
    address public voter;
    address public veALCX;
    address public admin; // the timelock executor
    address public pendingAdmin; // the timelock executor

    mapping(uint256 => uint256) public unclaimedFlux; // tokenId => amount of unclaimed flux

    constructor(address _minter) {
        require(_minter != address(0), "FluxToken: minter cannot be zero address");
        minter = _minter;
        voter = _minter;
        veALCX = _minter;
        admin = _minter;
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
}
