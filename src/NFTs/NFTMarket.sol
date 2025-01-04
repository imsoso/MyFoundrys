// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

contract NFTMarket {
    IERC20 public token;
    IERC721 public nft;

    struct NFT {
        // uint256 tokenId;
        address seller;
        uint256 price;
    }
    mapping(uint256 => NFT) public nfts;

    error PriceGreaterThanZero();
    error MustBeTheOwner();

    constructor() {}

    function listNFT(uint tokenId, uint price) public {}

    function buyNFT() public {}
}
