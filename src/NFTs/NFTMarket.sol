// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import '../BaseTokens/ERC20WithPermit.sol';

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { EIP712 } from '@openzeppelin/contracts/utils/cryptography/EIP712.sol';

contract NFTMarket is IERC721Receiver, ReentrancyGuard, Ownable, EIP712 {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    IERC20 public immutable token;
    IERC721 public immutable nftmarket;
    address public constant ETH_FLAG = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    address public whitelistSigner;
    IERC20Permit public immutable tokenPermit;

    struct NFT {
        address seller;
        uint256 price;
    }
    mapping(uint256 => NFT) public nfts;

    struct SellOrder {
        address seller;
        uint256 tokenId;
        address payToken;
        uint256 price;
        uint256 deadline;
    }
    mapping(uint256 => SellOrder) public listingOrders; // tokenID -> order book

    error PriceGreaterThanZero();
    error MustBeTheOwner();
    error MustNotBeTheOwner();
    error NotEnoughToken();

    error TokenTransferFailed();
    error NotERC20Contract();
    error NFTNotListed();
    error YouCannotAffordThis();
    error IncorrectPayment(uint256 expected, uint256 received);
    error NotTheSeller();
    error NotSignedByWhitelist();
    error InvalidWhitelistSigner();

    error SignatureExpired();
    error InvalidPayToken();
    error OrderAleardyListed();
    error InvalidSignature();
    error NotEnoughETH();
    error IncorrectETHAmount();

    event WhitelistBuy(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTSold(address indexed seller, address indexed buyer, uint256 price);
    event NFTListedWithSignature(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price,
        uint256 deadline,
        bytes signature,
        bool isValid
    );

    constructor(address initialOwner, address _nft, address _token) Ownable(initialOwner) EIP712('NFTMarket', '1') {
        nftmarket = IERC721(_nft);
        token = IERC20(_token);

        whitelistSigner = msg.sender;
        tokenPermit = IERC20Permit(_token);
    }

    // NFTOwner can list a NFT with a price
    function listNFT(uint tokenID, uint price) public {
        if (price == 0) {
            revert PriceGreaterThanZero();
        }

        if (nftmarket.ownerOf(tokenID) != msg.sender) {
            revert MustBeTheOwner();
        }

        if (nfts[tokenID].seller != address(0)) {
            revert OrderAleardyListed();
        }

        nftmarket.safeTransferFrom(msg.sender, address(this), tokenID);
        nfts[tokenID] = NFT(msg.sender, price);

        emit NFTListed(tokenID, msg.sender, price);
    }

    function buyNFT(address buyer, uint tokenID) public payable nonReentrant {
        NFT memory theNFT = nfts[tokenID];
        // check own buyer
        if (theNFT.seller == buyer) {
            revert MustNotBeTheOwner();
        }

        // check enough token
        if (token.balanceOf(buyer) < theNFT.price) {
            revert NotEnoughToken();
        }

        if (theNFT.seller == address(0)) {
            revert NFTNotListed();
        }

        // transfer token to seller
        bool success = token.transferFrom(buyer, theNFT.seller, theNFT.price);
        if (!success) {
            revert TokenTransferFailed();
        }
        // transfer nft to buyer
        nftmarket.transferFrom(address(this), buyer, tokenID);

        // delete nft
        delete nfts[tokenID];

        emit NFTSold(theNFT.seller, buyer, theNFT.price);
    }

    function tokensReceived(address from, uint256 amount, bytes calldata userData) internal {
        if (msg.sender != address(token)) {
            revert NotERC20Contract();
        }

        uint256 tokenId = abi.decode(userData, (uint));
        NFT memory theNFT = nfts[tokenId];
        if (theNFT.price == 0) {
            revert NFTNotListed();
        }

        if (amount != theNFT.price) {
            revert IncorrectPayment(theNFT.price, amount);
        }

        bool success = token.transfer(theNFT.seller, amount);
        if (!success) {
            revert TokenTransferFailed();
        }

        nftmarket.safeTransferFrom(address(this), from, tokenId);
        delete nfts[tokenId];

        emit NFTSold(theNFT.seller, msg.sender, theNFT.price);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        // do nothing but override here
        return IERC721Receiver.onERC721Received.selector;
    }

    function permitBuy(
        uint256 tokenID,
        uint256 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory whitelistSignature
    ) external {
        if (deadline < block.timestamp) {
            revert SignatureExpired();
        }

        NFT memory theNFT = nfts[tokenID];
        if (theNFT.seller == address(0)) {
            revert NFTNotListed();
        }

        if (msg.sender == theNFT.seller) {
            revert NotTheSeller();
        }

        if (price != theNFT.price) {
            revert IncorrectPayment(theNFT.price, price);
        }

        bytes32 messageWithSenderAndToken = keccak256(abi.encodePacked(msg.sender, tokenID));
        bytes32 ethSignedWithSenderAndToken = messageWithSenderAndToken.toEthSignedMessageHash();
        address theSigner = ethSignedWithSenderAndToken.recover(whitelistSignature);
        if (theSigner != whitelistSigner) {
            revert NotSignedByWhitelist();
        }

        tokenPermit.permit(msg.sender, address(this), price, deadline, v, r, s);

        buyNFT(msg.sender, tokenID);

        emit WhitelistBuy(tokenID, msg.sender, price);
    }

    function buyWithETH(uint256 tokenID) external payable {
        SellOrder memory theOrder = listingOrders[tokenID];
        NFT memory theNFT = nfts[tokenID];

        address buyer = msg.sender;

        // check own buyer
        if (theNFT.seller == buyer) {
            revert MustNotBeTheOwner();
        }

        if (theNFT.seller == address(0)) {
            revert NFTNotListed();
        }

        if (theOrder.payToken == ETH_FLAG) {
            if (msg.value != theOrder.price) {
                revert NotEnoughETH();
            }
        } else {
            if (msg.value != 0) {
                revert IncorrectETHAmount();
            }
        }

        // transfer nft to buyer
        nftmarket.transferFrom(address(this), buyer, tokenID);

        // delete nft
        delete nfts[tokenID];
        delete listingOrders[tokenID];

        emit NFTSold(theNFT.seller, buyer, theNFT.price);
    }

    function setWhitelistSigner(address _whitelistSigner) external onlyOwner {
        if (_whitelistSigner == address(0)) {
            revert InvalidWhitelistSigner();
        }
        whitelistSigner = _whitelistSigner;
    }

    function listWithSignature(uint256 tokenId, address payToken, uint256 price, uint256 deadline, bytes memory signature) external {
        if (deadline < block.timestamp) revert SignatureExpired();
        if (price == 0) revert PriceGreaterThanZero();
        if (payToken != ETH_FLAG && IERC20(payToken).totalSupply() == 0) {
            revert InvalidPayToken();
        }

        if (listingOrders[tokenId].seller != address(0)) {
            revert OrderAleardyListed();
        }

        SellOrder memory theOrder = SellOrder({
            seller: msg.sender,
            tokenId: tokenId,
            payToken: payToken,
            price: price,
            deadline: deadline
        });

        bytes32 hashedOrder = keccak256(abi.encode(theOrder));
        // safe check repeat list
        if (listingOrders[tokenId].seller != address(0)) {
            revert OrderAleardyListed();
        }

        bytes32 digest;

        if (theOrder.payToken == ETH_FLAG) {
            digest = MessageHashUtils.toEthSignedMessageHash(hashedOrder);
        } else {
            digest = _hashTypedDataV4(hashedOrder);
        }
        address theSigner = ECDSA.recover(digest, signature);
        if (theSigner != msg.sender) {
            revert InvalidSignature();
        }

        listingOrders[tokenId] = theOrder;
        emit NFTListedWithSignature(tokenId, theSigner, price, deadline, signature, true);
    }

    // verify signed listing
    function verifySignedListing(
        uint256 tokenId,
        uint256 price,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool isValid, address signer) {
        if (deadline < block.timestamp) return (false, address(0));

        bytes32 messageWithSenderAndToken = keccak256(abi.encodePacked(address(this), tokenId, price, deadline, block.chainid));
        bytes32 ethSignedWithSenderAndToken = messageWithSenderAndToken.toEthSignedMessageHash();
        address theSigner = ethSignedWithSenderAndToken.recover(signature);

        return (theSigner == nftmarket.ownerOf(tokenId), theSigner);
    }
}
