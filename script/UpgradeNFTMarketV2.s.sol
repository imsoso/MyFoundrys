// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import 'forge-std/Script.sol';
import { NFTMarketV2 } from '../src/Upgrade/NFTMarketV2.sol';
import { Upgrades } from 'openzeppelin-foundry-upgrades/Upgrades.sol';
import '@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol';
// 代理合约地址: 0xd6BF064b8dF28ccE17Fb08EF68E111362946D207
// ProxyAdmin 地址: 0xD14B5B86A7A3aBDE0254a57251fC7653a3fF7424
// 实现合约地址: 0xA9Ac7f44B24421dacc4eE7CDc76942e7610aF77e
// 所有者: 0x2e04aF48d11F4E505F09e253B119BfDa6772df54
contract UpgradeNFTMarketV2Script is Script {
    address constant PROXY_ADDRESS = address(0xd6BF064b8dF28ccE17Fb08EF68E111362946D207);
    address constant Token_ADDRESS = address(0x68AAaf6908F070b6ef06a486ca5838fe63E0Ca97);
    address constant NFT_ADDRESS = address(0x4c65bDEA9e905992731d5727F7Fe86EaD464518C);

    function run() external {
        address owner = vm.envAddress('OWNER_ADDRESS');
        console.log('Owner address is:', owner);

        vm.startBroadcast();
        // Upgrade to V2
        Upgrades.upgradeProxy(PROXY_ADDRESS, 'NFTMarketV2.sol:NFTMarketV2', '');
        NFTMarketV2 nftmarketV2 = NFTMarketV2(PROXY_ADDRESS);

        vm.stopBroadcast();

        console.log('\n=== Deployment Summary ===');
        console.log('Network:', block.chainid);
        console.log('NFTMarket V2 Implementation:', address(nftmarketV2));
    }
}
