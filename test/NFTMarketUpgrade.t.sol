// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test, console } from 'forge-std/Test.sol';
import { NFTMarketV1 } from '../src/Upgrade/NFTMarketV1.sol';
import { NFTMarketV2 } from '../src/Upgrade/NFTMarketV2.sol';
import '../src/BaseTokens/ERC20WithPermit.sol';
import '../src/NFTs/MyNFT.sol';

import { Upgrades } from 'openzeppelin-foundry-upgrades/Upgrades.sol';

contract NFTMarketUpgrade is Test {
    NFTMarketV1 public nftMarketV1;
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
            'NFTMarketV1.sol',
            address(proxyAdmin),
            abi.encodeCall(NFTMarketV1.initialize, (address(aNFT), address(aToken), owner)),
            aOpt
        );
        nftMarketV1 = NFTMarketV1(proxy);
        nftMarketV2 = NFTMarketV2(proxy);
    }
}
