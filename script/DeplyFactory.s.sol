// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import 'forge-std/Script.sol';
import '../src/upgrade/InscriptionToken.sol';
import { InscriptionFactoryV1 } from '../src/Upgrade/InscriptionFactoryV1.sol';
import { InscriptionFactoryV2 } from '../src/Upgrade/InscriptionFactoryV2.sol';

contract DeployScript is Script {
    function setUp() public {}

    function run() external {}
}
