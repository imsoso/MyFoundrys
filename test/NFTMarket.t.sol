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
    address seller = makeAddr('alice');
    address buyer = makeAddr('bob');

    function setUp() public {
        owner = address(this);
        token = new TokenWithCallback(owner);
        nft = new SoNFT(owner);
        nftMarket = new NFTMarket(address(nft), address(token));

        nft.safeMint(seller, 'https://chocolate-acceptable-hawk-967.mypinata.cloud/ipfs/QmSpTwSkZy8Hx7xBDrugDmbzRf5kkwnsVxdsbcAnaHAawu/0');
    }

    function test_ListNFT() public {
        // assertEq(counter.number(), 1);
    }
}
