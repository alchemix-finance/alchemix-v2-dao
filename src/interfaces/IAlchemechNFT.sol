// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

interface IAlchemechNFT is IERC721 {
    function mint(uint256 _tokenId, uint256 _tokenData, address _receiver) external;

    function tokenData(uint256 _tokenId) external view returns (uint256);
}
