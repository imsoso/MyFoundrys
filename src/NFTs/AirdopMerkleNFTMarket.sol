// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

contract AirdopMerkleNFTMarket is IERC721Receiver, Ownable {
    IERC721 public nftContract;

    IERC20 public nftToken;

    struct NFTProduct {
        uint256 price;
        address seller;
    }

    mapping(uint256 => NFTProduct) public NFTList;

    constructor(address _nftContract, address _nftToken, address initialOwner) Ownable(initialOwner) {
        nftContract = IERC721(_nftContract);
        nftToken = IERC20(_nftToken);
    }

    // List NFT on the market
    function list(uint256 tokenId, uint256 price) external {
        require(nftContract.ownerOf(tokenId) == msg.sender, 'You are not the owner');
        require(price > 0, 'Price must be greater than zero');
        // Transfer NFT to the market, make it available for sale
        nftContract.safeTransferFrom(msg.sender, address(this), tokenId);
        NFTList[tokenId] = NFTProduct({ price: price, seller: msg.sender });
    }
    function buyNFT(address buyer, uint256 amount, uint256 nftId) public {
        NFTProduct memory aNFT = NFTList[nftId];
        //You cannot buy your own NFT
        require(aNFT.seller != buyer, 'You cannot buy your own NFT');

        require(nftToken.balanceOf(buyer) >= amount, 'Insufficient payment token balance');

        require(amount == aNFT.price, 'Insufficient token amount to buy NFT');
        require(nftToken.transferFrom(buyer, aNFT.seller, aNFT.price), 'Token transfer failed');

        nftContract.transferFrom(address(this), buyer, nftId);
        delete NFTList[nftId];
    }

    function tokensReceived(address from, uint256 amount, bytes calldata userData) external {
        require(msg.sender == address(nftToken), 'Only the ERC20 token contract can call this');
        uint256 tokenId = abi.decode(userData, (uint256));
        NFTProduct memory aNFT = NFTList[tokenId];
        require(aNFT.price > 0, 'NFT is not listed for sale');
        require(amount == aNFT.price, 'Incorrect payment amount');

        nftContract.safeTransferFrom(address(this), from, tokenId);
        nftToken.transfer(aNFT.seller, amount);
        delete NFTList[tokenId];
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        // do nothing here
        return IERC721Receiver.onERC721Received.selector;
    }
}
