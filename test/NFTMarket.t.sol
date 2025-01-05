// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from 'forge-std/Test.sol';
import { NFTMarket } from '../src/NFTs/NFTMarket.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract NFTMarketTest is Test {
    NFTMarket public nftMarket;
    ERC20 public token;
    ERC721 public nft;

    function setUp() public {
        token = new ERC20('Token', 'TOK', 18);
        nft = new ERC721('NFT', 'NFT');

        NFTMarket = new NFTMarket(address(nft), address(token));
    }

    }
}
