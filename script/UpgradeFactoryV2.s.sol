// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import 'forge-std/Script.sol';
import '../src/upgrade/InscriptionToken.sol';
import { InscriptionFactoryV2 } from '../src/Upgrade/InscriptionFactoryV2.sol';
import { Upgrades } from 'openzeppelin-foundry-upgrades/Upgrades.sol';

contract UpgradeFactoryV2Script is Script {
    address constant PROXY_ADDRESS = address(0xe5b3EBa82Bb3F9D41AA9dD65C8d1d42EbCB02Df1);

    function run() external {
        address owner = vm.envAddress('OWNER_ADDRESS');
        console.log('Owner address is:', owner);

        vm.startBroadcast();

        // 1. Upgrade to V2
        Upgrades.upgradeProxy(PROXY_ADDRESS, 'InscriptionFactoryV2.sol', abi.encodeCall(InscriptionFactoryV2.initialize, owner));
        console.log('Proxy deployed at:', PROXY_ADDRESS);

        // 2. Deploy a new token using V2 interface
        uint price = 0.01 ether;
        InscriptionFactoryV2 factoryV2 = InscriptionFactoryV2(PROXY_ADDRESS);
        address tokenAddrV2 = factoryV2.deployInscription('TOKENV2', 5000, 50, price);

        vm.stopBroadcast();

        console.log('\n=== Deployment Summary ===');
        console.log('Network:', block.chainid);
        console.log('Inscription Token V2 Implementation:', tokenAddrV2);

        console.log('Factory V2 Implementation:', address(factoryV2));

        console.log('Proxy:', PROXY_ADDRESS);
    }
}
