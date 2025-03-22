// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import 'forge-std/Test.sol';
import 'forge-std/console2.sol';
import '@openzeppelin-upgradeable/contracts/utils/PausableUpgradeable.sol';
import '../src/NFTs/MyInscription.sol';
import '../src/NFTs/MyInscriptionV2.sol';
import '../src/BaseTokens/InscriptionToken.sol';

bytes32 constant SALT = bytes32(uint256(0x0000000000000000000000000000000000000000d3bf2663da51c10215000003));

contract InscriptionTest is Test {}
