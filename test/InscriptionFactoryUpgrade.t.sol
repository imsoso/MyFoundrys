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
    address public user;

    function setUp() public {
        owner = address(this);
        user = makeAddr('user');
        address proxy = Upgrades.deployUUPSProxy('InscriptionFactoryV1.sol', abi.encodeCall(InscriptionFactoryV1.initialize, owner));
        factoryV1 = InscriptionFactoryV1(proxy);
        factoryV2 = InscriptionFactoryV2(proxy);
        // Fund test users
        vm.deal(user, 100 ether);
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
        vm.prank(user);
        factoryV1.mintInscription(tokenAddrV1);
        InscriptionToken token = InscriptionToken(tokenAddrV1);
        assertEq(token.balanceOf(user), 10, 'V1 mint failed, user balance mismatch');
        (, , ma) = factoryV1.tokenInfos(tokenAddrV1); // Get only mintedAmount
        assertEq(ma, 10, 'V1 minted amount after mint mismatch');
    }

    // --- Test Upgrade Process ---
    function test_Upgrade_ToV2() public {
        // 1. Deploy a token using V1
        address tokenAddrV1 = factoryV1.deployInscription('TOKENV1', 1000, 10);
        vm.prank(user);
        factoryV1.mintInscription(tokenAddrV1); // Mint 10
        // 2. Upgrade to V2
        vm.prank(owner); // Ensure owner context for upgrade
        Upgrades.upgradeProxy(address(factoryV1), 'InscriptionFactoryV2.sol', abi.encodeCall(InscriptionFactoryV2.initialize, owner));
        // 3. Access V1 token data using V2 interface
        (uint256 tsV2, uint256 pmV2, uint256 maV2, uint256 priceV2) = factoryV2.tokenInfos(tokenAddrV1);
        assertEq(tsV2, 1000, 'Post-upgrade V1 total supply mismatch');
        assertEq(pmV2, 10, 'Post-upgrade V1 per mint mismatch');
        assertEq(maV2, 10, 'Post-upgrade V1 minted amount mismatch');
        // Price was not set in V1's storage slot, so it defaults to 0 when read via V2 struct
        assertEq(priceV2, 0, 'Post-upgrade V1 price should be 0');
    }

    function test_PostUpgrade_DeployAndMintV2Token_PotentialIssue() public {
        // 1. Upgrade to V2
        vm.prank(owner); // Ensure owner context for upgrade
        Upgrades.upgradeProxy(address(factoryV1), 'InscriptionFactoryV2.sol', abi.encodeCall(InscriptionFactoryV2.initialize, owner));

        address tokenAddrV2 = factoryV2.deployInscription('TOKENV2', 5000, 50, 0.01 ether);
        // If deploy succeeds (e.g., after manual storage set or V2 modification):
        assertTrue(tokenAddrV2 != address(0), 'V2 deployment failed post-upgrade');
        InscriptionFactoryV2.TokenInfo memory info;
        (info.totalSupply, info.perMint, info.mintedAmount, info.price) = factoryV2.tokenInfos(tokenAddrV2);
        assertEq(info.totalSupply, 5000, 'V2 total supply mismatch');
        assertEq(info.perMint, 50, 'V2 per mint mismatch');
        assertEq(info.price, 0.01 ether, 'V2 price mismatch');
        assertEq(info.mintedAmount, 0, 'V2 initial minted amount mismatch');
        // Mint using V2 (requires payment)
        uint256 cost = info.price * info.perMint; // 0.01 ether * 50 = 0.5 ether
        vm.deal(user, cost); // Give user funds
        vm.prank(user);
        factoryV2.mintInscription{ value: cost }(tokenAddrV2);
        InscriptionToken token = InscriptionToken(tokenAddrV2);
        assertEq(token.balanceOf(user), 50, 'V2 mint failed, user balance mismatch');
        (info.totalSupply, info.perMint, info.mintedAmount, info.price) = factoryV2.tokenInfos(tokenAddrV2); // Re-fetch info after mint
        assertEq(info.mintedAmount, 50, 'V2 minted amount after mint mismatch');
        assertEq(address(factoryV2).balance, cost, 'Factory balance mismatch after V2 mint'); // Check if factory received payment correctly

        vm.deal(user, cost); // Give user funds again
        // Test insufficient payment
        vm.prank(user);
        vm.expectRevert(InscriptionFactoryV2.InsufficientPayment.selector);
        factoryV2.mintInscription{ value: cost - 1 }(tokenAddrV2);
    }
}
