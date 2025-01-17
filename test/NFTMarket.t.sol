// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from 'forge-std/Test.sol';
import { NFTMarket } from '../src/NFTs/NFTMarket.sol';
import '../src/BaseTokens/TokenWithCallback.sol';
import '../src/NFTs/MyNFT.sol';

contract NFTMarketTest is Test {
    NFTMarket public nftMarket;
    TokenWithCallback public token;
    SoNFT public nft;

    address public owner;

    function setUp() public {
        owner = address(this);
        token = new TokenWithCallback(owner);
        nft = new SoNFT(owner);

        nftMarket = new NFTMarket(address(nft), address(token));
    }

    }
}
