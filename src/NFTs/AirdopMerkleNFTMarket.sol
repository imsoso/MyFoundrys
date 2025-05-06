// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { SoToken } from '../BaseTokens/ERC20WithPermit.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

contract AirdopMerkleNFTMarket is IERC721Receiver, Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    IERC721 public nftContract;
    SoToken public soToken;
    address public whitelistSigner;

    struct NFTProduct {
        uint256 price;
        address seller;
    }
    mapping(uint256 => NFTProduct) public NFTList;

    error SignatureExpired();
    error NFTNotListed();
    error NotTheSeller();
    error IncorrectPayment(uint256 expected, uint256 received);
    error NotSignedByWhitelist();

    event PermitPrePay(address indexed buyer, uint256 price);
    event WhitelistBuy(address indexed buyer, uint256 amount, uint256 nftId);
    event ClaimNFT(uint256 nftId, uint256 amount);

    constructor(address _nftContract, address initialOwner) Ownable(initialOwner) {
        nftContract = IERC721(_nftContract);
        soToken = SoToken(initialOwner);
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

    function whiteListBuyNFT(address buyer, uint256 amount, uint256 nftId) public {
        NFTProduct memory aNFT = NFTList[nftId];
        //You cannot buy your own NFT
        require(aNFT.seller != buyer, 'You cannot buy your own NFT');

        require(nftToken.balanceOf(buyer) >= amount, 'Insufficient payment token balance');

        require(amount < aNFT.price / 2, 'Insufficient token amount to buy NFT');
        require(nftToken.transferFrom(buyer, aNFT.seller, aNFT.price / 2), 'Token transfer failed');

        nftContract.transferFrom(address(this), buyer, nftId);
        delete NFTList[nftId];
    }

    function permitPrePay(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        if (deadline < block.timestamp) {
            revert SignatureExpired();
        }

        soToken.permit(msg.sender, address(this), amount, deadline, v, r, s);

        emit PermitPrePay(msg.sender, amount);
    }

    function claimNFT(uint256 nftId, uint256 price, bytes memory whitelistSignature) external {
        NFTProduct memory theNFT = NFTList[nftId];
        if (theNFT.seller == address(0)) {
            revert NFTNotListed();
        }

        if (msg.sender == theNFT.seller) {
            revert NotTheSeller();
        }

        if (price != theNFT.price) {
            revert IncorrectPayment(theNFT.price, price);
        }

        bytes32 messageWithSenderAndToken = keccak256(abi.encodePacked(msg.sender, nftId));
        bytes32 ethSignedWithSenderAndToken = messageWithSenderAndToken.toEthSignedMessageHash();
        address theSigner = ethSignedWithSenderAndToken.recover(whitelistSignature);
        if (theSigner != whitelistSigner) {
            revert NotSignedByWhitelist();
        }

        whiteListBuyNFT(msg.sender, price, nftId);

        emit ClaimNFT(nftId, price);
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
