// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test, console } from 'forge-std/Test.sol';
import { InscriptionFactoryV1 } from '../src/Upgrade/InscriptionFactoryV1.sol';
import { InscriptionFactoryV2 } from '../src/Upgrade/InscriptionFactoryV2.sol';
import { InscriptionToken } from '../src/Upgrade/InscriptionToken.sol';

import { Upgrades } from 'openzeppelin-foundry-upgrades/Upgrades.sol';

contract InscriptionFactoryUpgradeTest is Test {
    InscriptionToken public inscriptionToken;
    InscriptionFactoryV1 public factoryV1;
    InscriptionFactoryV2 public factoryV2;

    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr('user1');
        user2 = makeAddr('user2');
        address proxy = Upgrades.deployUUPSProxy('InscriptionFactoryV1.sol', abi.encodeCall(InscriptionFactoryV1.initialize, owner));
        factoryV1 = InscriptionFactoryV1(proxy);
        // Fund test users
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    // --- Test V1 Functionality Before Upgrade ---

    function test_V1_DeployAndMint() public {
        // Deploy a token using V1
        address tokenAddrV1 = factoryV1.deployInscription('TOKENV1', 1000, 10);
        assertTrue(tokenAddrV1 != address(0), 'V1 deployment failed');
        (uint256 ts, uint256 pm, uint256 ma) = factoryV1.tokenInfos(tokenAddrV1);
        assertEq(ts, 1000, 'V1 total supply mismatch');
        assertEq(pm, 10, 'V1 per mint mismatch');
        assertEq(ma, 0, 'V1 initial minted amount mismatch');
        // Price should be default 0 for V1 struct slot, even if accessed via V2 interface later

        // Mint using V1
        vm.prank(user1);
        factoryV1.mintInscription(tokenAddrV1);
        InscriptionToken token = InscriptionToken(tokenAddrV1);
        assertEq(token.balanceOf(user1), 10, 'V1 mint failed, user balance mismatch');
        (, , ma) = factoryV1.tokenInfos(tokenAddrV1); // Get only mintedAmount
        assertEq(ma, 10, 'V1 minted amount after mint mismatch');
    }
}
