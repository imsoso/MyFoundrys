// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

import '@openzeppelin-upgradeable/contracts/utils/cryptography/EIP712Upgradeable.sol';

/// @custom:oz-upgrades-from NFTMarketV1
contract NFTMarketV2 is IERC721Receiver, Initializable, OwnableUpgradeable, EIP712Upgradeable {
    IERC721 public nftContract;

    IERC20 public nftToken;

    struct NFTProduct {
        uint256 price;
        address seller;
    }

    struct SellOrder {
        address seller;
        uint256 tokenId;
        uint256 price;
        uint256 deadline;
    }

    mapping(uint256 => NFTProduct) public NFTList;
    mapping(uint256 => SellOrder) public listingOrders; // tokenID -> order book

    error PriceGreaterThanZero();
    error SignatureExpired();
    error OrderAleardyListed();
    error InvalidSignature();

    event NFTListedWithSignature(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price,
        uint256 deadline,
        bytes signature,
        bool isValid
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // initialize function
    /// @custom:oz-upgrades-validate-as-initializer
    function initialize(address _nftContract, address _nftToken, address initialOwner) public reinitializer(2) {
        __Ownable_init(initialOwner);
        __EIP712_init('NFTMarket', '1');

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

    function listWithSignature(uint256 tokenId, uint256 price, uint256 deadline, bytes memory signature) external {
        if (deadline < block.timestamp) revert SignatureExpired();
        if (price == 0) revert PriceGreaterThanZero();

        if (listingOrders[tokenId].seller != address(0)) {
            revert OrderAleardyListed();
        }

        SellOrder memory theOrder = SellOrder({ seller: msg.sender, tokenId: tokenId, price: price, deadline: deadline });

        bytes32 hashedOrder = keccak256(abi.encode(theOrder));
        // safe check repeat list
        if (listingOrders[tokenId].seller != address(0)) {
            revert OrderAleardyListed();
        }

        bytes32 digest = _hashTypedDataV4(hashedOrder);

        address theSigner = ECDSA.recover(digest, signature);
        if (theSigner != msg.sender) {
            revert InvalidSignature();
        }

        listingOrders[tokenId] = theOrder;
        emit NFTListedWithSignature(tokenId, theSigner, price, deadline, signature, true);
    }

    // Helper function to expose _hashTypedDataV4 for tests
    function hashTypedData(bytes32 structHash) external view returns (bytes32) {
        return _hashTypedDataV4(structHash);
    }
}
