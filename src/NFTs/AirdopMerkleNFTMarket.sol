// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { SoToken } from '../BaseTokens/ERC20WithPermit.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/Multicall.sol';

contract AirdopMerkleNFTMarket is IERC721Receiver, Ownable, Multicall {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    IERC721 public nftContract;
    SoToken public soToken;

    struct NFTProduct {
        uint256 price;
        address seller;
    }
    mapping(uint256 => NFTProduct) public NFTList;
    mapping(address => bool) public claimedAddress; // can claim only once

    error SignatureExpired();
    error NFTNotListed();
    error NotTheSeller();
    error IncorrectPayment(uint256 expected, uint256 received);
    error NotSignedByWhitelist();
    error NFTAlreadyClaimed();

    event PermitPrePay(address indexed buyer, uint256 price);
    event WhitelistBuy(address indexed buyer, uint256 price, uint256 nftId);
    event ClaimNFT(uint256 nftId, uint256 price);

    constructor(address _nftContract, address initialOwner) Ownable(initialOwner) {
        nftContract = IERC721(_nftContract);
        soToken = SoToken(initialOwner);
    }

    // List NFT on the market
    function list(uint256 nftId, uint256 price) external {
        require(nftContract.ownerOf(nftId) == msg.sender, 'You are not the owner');
        require(price > 0, 'Price must be greater than zero');
        // Transfer NFT to the market, make it available for sale
        nftContract.safeTransferFrom(msg.sender, address(this), nftId);
        NFTList[nftId] = NFTProduct({ price: price, seller: msg.sender });
    }

    function buyNFT(address buyer, uint256 price, uint256 nftId) public {
        NFTProduct memory aNFT = NFTList[nftId];
        //You cannot buy your own NFT
        require(aNFT.seller != buyer, 'You cannot buy your own NFT');

        require(soToken.balanceOf(buyer) >= price, 'Insufficient payment token balance');

        require(price == aNFT.price, 'Insufficient token price to buy NFT');
        require(soToken.transferFrom(buyer, aNFT.seller, aNFT.price), 'Token transfer failed');

        nftContract.transferFrom(address(this), buyer, nftId);
        delete NFTList[nftId];
    }

    function whiteListBuyNFT(address buyer, uint256 price, uint256 nftId) public {
        NFTProduct memory aNFT = NFTList[nftId];
        //You cannot buy your own NFT
        require(aNFT.seller != buyer, 'You cannot buy your own NFT');

        require(soToken.balanceOf(buyer) >= price, 'Insufficient payment token balance');

        require(price < aNFT.price / 2, 'Insufficient token price to buy NFT');
        require(soToken.transferFrom(buyer, aNFT.seller, aNFT.price / 2), 'Token transfer failed');

        nftContract.transferFrom(address(this), buyer, nftId);
        delete NFTList[nftId];
    }

    function permitPrePay(uint256 price, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        if (deadline < block.timestamp) {
            revert SignatureExpired();
        }

        soToken.permit(msg.sender, address(this), price, deadline, v, r, s);

        emit PermitPrePay(msg.sender, price);
    }

    function claimNFT(uint256 nftId, uint256 price, bytes32[] calldata proof, bytes32 merkleRoot) external {
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

        if (!verifyWhitelistWithMerkleTree(msg.sender, proof, merkleRoot)) {
            revert NotSignedByWhitelist();
        }

        if (claimedAddress[msg.sender]) {
            revert NFTAlreadyClaimed();
        }

        whiteListBuyNFT(msg.sender, price, nftId);
        claimedAddress[msg.sender] = true;

        emit ClaimNFT(nftId, price);
    }

    function tokensReceived(address from, uint256 price, bytes calldata userData) external {
        require(msg.sender == address(soToken), 'Only the ERC20 token contract can call this');
        uint256 theNftId = abi.decode(userData, (uint256));
        NFTProduct memory aNFT = NFTList[theNftId];
        require(aNFT.price > 0, 'NFT is not listed for sale');
        require(price == aNFT.price, 'Incorrect payment price');

        nftContract.safeTransferFrom(address(this), from, theNftId);
        soToken.transfer(aNFT.seller, price);
        delete NFTList[theNftId];
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        // do nothing here
        return IERC721Receiver.onERC721Received.selector;
    }

    function verifyWhitelistWithMerkleTree(address user, bytes32[] calldata proof, bytes32 merkleRoot) internal pure returns (bool) {
        // calculate the leaf node hash
        bytes32 leaf = keccak256(abi.encodePacked(user));

        // verify if the user is in the whitelist
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}
