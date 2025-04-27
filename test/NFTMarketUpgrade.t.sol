// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test, console } from 'forge-std/Test.sol';
import { NFTMarket } from '../src/Upgrade/NFTMarketV1.sol';
import { NFTMarketV2 } from '../src/Upgrade/NFTMarketV2.sol';
import '../src/BaseTokens/ERC20WithPermit.sol';
import '../src/NFTs/MyNFT.sol';

import { Upgrades } from 'openzeppelin-foundry-upgrades/Upgrades.sol';

contract NFTMarketUpgrade is Test {
    NFTMarket public nftMarketV1;
    NFTMarketV2 public nftMarketV2;

    SoToken public aToken;
    SoNFT public aNFT;

    address public owner;
    address public user;

    function setUp() public {
        owner = address(this);
        user = makeAddr('user');

        aToken = new SoToken(owner);
        aNFT = new SoNFT(owner);

        address proxy = Upgrades.deployTransparentProxy(
            'NFTMarket.sol',
            owner,
            abi.encodeCall(NFTMarket.initialize, (address(aNFT), address(aToken), owner))
        );
        nftMarketV1 = NFTMarket(proxy);
        nftMarketV2 = NFTMarketV2(proxy);
        // Fund test users
        vm.deal(user, 100 ether);
    }
}
