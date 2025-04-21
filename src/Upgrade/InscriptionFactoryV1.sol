// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.28;

import { UUPSUpgradeable } from '@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol';
import { OwnableUpgradeable } from '@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol';
import { Initializable } from '@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol';
import { InscriptionToken } from './InscriptionToken.sol';

contract InscriptionFactoryV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    InscriptionToken aToken;

    constructor() {
        // disable initializer
        _disableInitializers();
    }

    // upgradeable init
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function deployInscription(string memory symbol, uint totalSupply, uint perMint) external returns (address) {
        aToken = new InscriptionToken('InscitionToken', 'IT', address(this));
    }
}
