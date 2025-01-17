// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import '../BaseTokens/TokenWithCallback.sol';

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

contract NFTMarket {
    TokenWithCallback public immutable token;
    IERC721 public immutable nftmarket;

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

    constructor(address _nft, address _token) {
        nftmarket = IERC721(_nft);
        token = TokenWithCallback(_token);
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
    }

    function buyNFT(uint tokenID) public {
        NFT memory theNFT = nfts[tokenID];
        address buyer = msg.sender;

        // check own buyer
        if (theNFT.seller == buyer) {
            revert MustNotBeTheOwner();
        }

        // check enough token
        if (token.balanceOf(buyer) < theNFT.price) {
            revert NotEnoughToken();
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
    }

    function tokensReceived(address from, uint256 amount, bytes calldata userData) external {
        if (msg.sender != address(nftmarket)) {
            revert NotERC20Contract();
        }

        uint256 tokenId = abi.decode(userData, (uint));
        NFT memory theNFT = nfts[tokenId];
        if (theNFT.price == 0) {
            revert NFTNotListed();
        }

        if (amount < theNFT.price) {
            revert YouCannotAffordThis();
        }

        bool success = token.transfer(theNFT.seller, amount);
        if (!success) {
            revert TokenTransferFailed();
        }

        nftmarket.safeTransferFrom(msg.sender, from, tokenId);
        delete nfts[tokenId];
    }
}
