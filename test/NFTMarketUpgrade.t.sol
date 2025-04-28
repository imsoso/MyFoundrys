// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test, console } from 'forge-std/Test.sol';
import { NFTMarketV1 } from '../src/Upgrade/NFTMarketV1.sol';
import { NFTMarketV2 } from '../src/Upgrade/NFTMarketV2.sol';
import '../src/BaseTokens/ERC20WithPermit.sol';
import '../src/NFTs/MyNFT.sol';

import { Upgrades } from 'openzeppelin-foundry-upgrades/Upgrades.sol';
import '@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol';

contract NFTMarketUpgrade is Test {
    NFTMarketV1 public nftMarketV1;
    NFTMarketV2 public nftMarketV2;

    SoToken public aToken;
    SoNFT public aNFT;
    uint256 nftId;

    address public admin;
    address public owner;

    address public seller;

    ProxyAdmin proxyAdmin;

    function setUp() public {
        owner = address(this);
        admin = makeAddr('admin');
        seller = makeAddr('seller');

        aToken = new SoToken(owner);
        aNFT = new SoNFT(owner);
        nftId = aNFT.mint(
            seller,
            'https://chocolate-acceptable-hawk-967.mypinata.cloud/ipfs/QmRWFi6XoDFchaZ25g8fTRxY3tc4E289AUQvpUcTqP3w7L'
        );

        address proxy = Upgrades.deployTransparentProxy(
            'NFTMarketV1.sol:NFTMarketV1',
            admin,
            abi.encodeCall(NFTMarketV1.initialize, (address(aNFT), address(aToken), owner))
        );
        nftMarketV1 = NFTMarketV1(proxy);
        nftMarketV2 = NFTMarketV2(proxy);
    }

    function test_V1_list_succeed() public {
        vm.startPrank(seller);
        aNFT.approve(address(nftMarketV1), nftId);
        nftMarketV1.list(nftId, 100);
        vm.stopPrank();
    }

    // --- Test Upgrade Process ---
    function test_Upgrade_ToV2() public {
        // Upgrade to V2
        vm.startPrank(admin); // Ensure owner context for upgrade
        Upgrades.upgradeProxy(
            address(nftMarketV1),
            'NFTMarketV2.sol:NFTMarketV2',
            abi.encodeCall(NFTMarketV2.initialize, (address(aNFT), address(aToken), owner))
        );
        vm.stopPrank(); // Ensure owner context for upgrade
    }
}
