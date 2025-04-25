// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import 'forge-std/Script.sol';
import '../src/upgrade/InscriptionToken.sol';
import { InscriptionFactoryV1 } from '../src/Upgrade/InscriptionFactoryV1.sol';
import { Upgrades } from 'openzeppelin-foundry-upgrades/Upgrades.sol';

contract DeployFactoryV1Script is Script {
    function run() external {
        vm.startBroadcast();

        address owner = vm.envAddress('OWNER_ADDRESS');
        console.log('Owner address is:', owner);

        address proxy = Upgrades.deployUUPSProxy('InscriptionFactoryV1.sol', abi.encodeCall(InscriptionFactoryV1.initialize, owner));
        console.log('Proxy deployed at:', address(proxy));

        InscriptionFactoryV1 factoryV1 = InscriptionFactoryV1(proxy);

        address tokenAddrV1 = factoryV1.deployInscription('TOKENV1', 1000, 10);

        vm.stopBroadcast();

        console.log('\n=== Deployment Summary ===');
        console.log('Network:', block.chainid);
        console.log('Inscription Token V1 Implementation:', tokenAddrV1);

        console.log('Factory V1 Implementation:', address(factoryV1));

        console.log('Proxy:', address(proxy));
    }
}
