// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.28;

import { UUPSUpgradeable } from '@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol';
import { OwnableUpgradeable } from '@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol';
import { Initializable } from '@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol';
import { InscriptionToken } from './InscriptionToken.sol';

contract InscriptionFactoryV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    struct TokenInfo {
        uint256 totalSupply; // total supply
        uint256 perMint; // per mint amount
        uint256 mintedAmount; // minted amount
    }
    mapping(address => TokenInfo) public tokenInfos;

    error PerMintExceedsTotalSupply();

    event InscriptionDeployed(address indexed tokenAddress, string symbol, uint256 totalSupply, uint256 perMint);

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
        // check per mint amount
        if (perMint > totalSupply) revert PerMintExceedsTotalSupply();

        address newToken = address(new InscriptionToken('InscitionToken', 'IT', address(this)));
        tokenInfos[newToken] = TokenInfo({ totalSupply: totalSupply, perMint: perMint, mintedAmount: 0 });
        emit InscriptionDeployed(newToken, symbol, totalSupply, perMint);
        return newToken;
    }
}
