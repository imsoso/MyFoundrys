// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import 'forge-std/Script.sol';
import { NFTMarketV1 } from '../src/Upgrade/NFTMarketV1.sol';
import { Upgrades } from 'openzeppelin-foundry-upgrades/Upgrades.sol';

contract DeployFactoryV1Script is Script {
    address constant Token_ADDRESS = address(0x68AAaf6908F070b6ef06a486ca5838fe63E0Ca97);
    address constant NFT_ADDRESS = address(0x4c65bDEA9e905992731d5727F7Fe86EaD464518C);

    function run() external {
        vm.startBroadcast();

        address owner = vm.envAddress('OWNER_ADDRESS');
        console.log('Owner address is:', owner);

        address proxy = Upgrades.deployTransparentProxy(
            'NFTMarketV1.sol:NFTMarketV1',
            owner,
            abi.encodeCall(NFTMarketV1.initialize, (NFT_ADDRESS, Token_ADDRESS, owner))
        );
        NFTMarketV1 nftMarketV1 = NFTMarketV1(proxy);

        console.log('Proxy deployed at:', address(proxy));

        vm.stopBroadcast();

        console.log('\n=== Deployment Summary ===');
        console.log('Network:', block.chainid);

        console.log('NFTMarket V1 Implementation:', address(nftMarketV1));

        console.log('Proxy:', address(proxy));
    }
}
