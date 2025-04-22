// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test, console } from 'forge-std/Test.sol';
import { InscriptionFactoryV1 } from '../src/Upgrade/InscriptionFactoryV1.sol';
import { InscriptionFactoryV2 } from '../src/Upgrade/InscriptionFactoryV2.sol';
import { InscriptionToken } from '../src/Upgrade/InscriptionToken.sol';

import { Upgrades } from 'openzeppelin-foundry-upgrades/Upgrades.sol';

contract InscriptionFactoryUpgradeTest is Test {
    InscriptionToken public implementationToken;
    InscriptionFactoryV1 public factoryV1Implementation;
    InscriptionFactoryV2 public factoryV2Implementation;

    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr('user1');
        user2 = makeAddr('user2');

        address proxy = Upgrades.deployUUPSProxy('MyUUPSProxy.sol', abi.encodeCall(InscriptionFactoryV1.initialize, owner));

        // Fund test users
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }
}
