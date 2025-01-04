// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from 'forge-std/Test.sol';
import { NFTMarket } from '../src/NFTs/NFTMarket.sol';

contract NFTMarketTest is Test {
    NFTMarket public nftMarket;

    function setUp() public {
        nftMarket = new NFTMarket();
    }
}
