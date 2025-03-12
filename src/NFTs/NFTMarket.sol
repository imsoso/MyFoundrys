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

contract NFTMarket is IERC721Receiver, ReentrancyGuard {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    IERC20 public immutable token;
    IERC721 public immutable nftmarket;

    address public whitelistSigner;
    IERC20Permit public immutable tokenPermit;

    struct NFT {
        // uint256 tokenId;
        address seller;
        uint256 price;
    }
    mapping(uint256 => NFT) public nfts;

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

    event WhitelistBuy(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTSold(address indexed seller, address indexed buyer, uint256 price);

    constructor(address _nft, address _token) {
        nftmarket = IERC721(_nft);
        token = IERC20(_token);

        whitelistSigner = msg.sender;
        tokenPermit = IERC20Permit(_token);
    }

    modifier onlyOwner() {
        require(msg.sender == address(this), 'Owner only');
        _;
    }

    // NFTOwner can list a NFT with a price
    function listNFT(uint tokenID, uint price) public {
        if (price == 0) {
            revert PriceGreaterThanZero();
        }

        if (nftmarket.ownerOf(tokenID) != msg.sender) {
            revert MustBeTheOwner();
        }

        nftmarket.safeTransferFrom(msg.sender, address(this), tokenID);
        nfts[tokenID] = NFT(msg.sender, price);

        emit NFTListed(tokenID, msg.sender, price);
    }

    function buyNFT(address buyer, uint tokenID) public nonReentrant {
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

    function tokensReceived(address from, uint256 amount, bytes calldata userData) external {
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

        nftmarket.safeTransferFrom(msg.sender, from, tokenId);
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

    function setWhitelistSigner(address _whitelistSigner) external onlyOwner {
        if (_whitelistSigner == address(0)) {
            revert InvalidWhitelistSigner();
        }
        whitelistSigner = _whitelistSigner;
    }
}
