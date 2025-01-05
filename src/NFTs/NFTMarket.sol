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
    error MustNotBeTheOwner();
    error NotEnoughToken();
    error NFTNotExist();
    error TokenTransferFailed();

    constructor(address _nft, address _token) {
        nft = IERC721(_nft);
        token = IERC20(_token);
    }
    // NFTOwner can list a NFT with a price
    function listNFT(uint nftId, uint price) public {
        if (price == 0) {
            revert PriceGreaterThanZero();
        }

        if (nft.ownerOf(nftId) != msg.sender) {
            revert MustBeTheOwner();
        }

        nft.safeTransferFrom(msg.sender, address(this), nftId);
        nfts[nftId] = NFT(msg.sender, price);
    }

    function buyNFT(uint nftId) public {
        NFT memory theNFT = nfts[nftId];
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
        nft.transferFrom(address(this), buyer, nftId);

        // delete nft
        delete nfts[nftId];
    }
}
