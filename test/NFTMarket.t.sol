// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from 'forge-std/Test.sol';
import { NFTMarket } from '../src/NFTs/NFTMarket.sol';
import '../src/BaseTokens/TokenWithCallback.sol';
import '../src/NFTs/MyNFT.sol';

contract NFTMarketTest is Test {
    NFTMarket public aNftMarket;
    TokenWithCallback public aToken;
    SoNFT public aNFT;
    uint256 nftId;

    address public owner;
    address seller = makeAddr('seller');
    address buyer = makeAddr('buyer');

    function setUp() public {
        owner = address(this);
        aToken = new TokenWithCallback(owner);
        aNFT = new SoNFT(owner);
        aNftMarket = new NFTMarket(address(aNFT), address(aToken));

        nftId = aNFT.mint(
            seller,
            'https://chocolate-acceptable-hawk-967.mypinata.cloud/ipfs/QmRWFi6XoDFchaZ25g8fTRxY3tc4E289AUQvpUcTqP3w7L'
        );
    }

    function test_list_not_owner() public {
        vm.expectRevert(NFTMarket.MustBeTheOwner.selector);
        aNftMarket.listNFT(nftId, 100);
    }

    function test_list_zero_price() public {
        vm.startPrank(seller);
        aNFT.approve(address(aNftMarket), nftId);
        vm.expectRevert(NFTMarket.PriceGreaterThanZero.selector);
        aNftMarket.listNFT(nftId, 0);
        vm.stopPrank();
    }

    function test_list_succeed() public {
        vm.startPrank(seller);
        aNFT.approve(address(aNftMarket), nftId);
        aNftMarket.listNFT(nftId, 100);
        vm.stopPrank();
    }

    function test_buy_insuficient_balance() public {
        vm.startPrank(seller);
        aNFT.approve(address(aNftMarket), nftId);

        aNftMarket.listNFT(nftId, 100);
        vm.stopPrank();

        deal(address(aToken), buyer, 10);
        vm.prank(buyer);
        aToken.approve(address(aNftMarket), 100);

        vm.expectRevert(NFTMarket.NotEnoughToken.selector);
        aNftMarket.buyNFT(buyer, nftId);
    }
    }
}
