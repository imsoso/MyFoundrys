// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.28;

import { Clones } from '@openzeppelin/contracts/proxy/Clones.sol';
import { Initializable } from '@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol';
import { OwnableUpgradeable } from '@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol';
import { UUPSUpgradeable } from '@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol';
import { InscriptionToken } from '../BaseTokens/InscriptionToken.sol';

contract MyInscription is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    InscriptionToken aToken;
    // token struct
    struct TokenInfo {
        uint256 totalSupply; // total supply
        uint256 perMint; // per mint amount
        uint256 mintedAmount; // minted amount
    }
    mapping(address => TokenInfo) public tokenInfo;

    address public implementationContract;

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

        // Deploy a token implementation contract as template
        InscriptionToken tokenImpl = new InscriptionToken();
        implementationContract = address(tokenImpl);
    }

    function deployInscription(string memory symbol, uint totalSupply, uint perMint) external returns (address) {
        // check per mint amount
        if (perMint > totalSupply) revert PerMintExceedsTotalSupply();

        address newToken = Clones.clone(implementationContract);
        InscriptionToken(newToken).initialize('MyInscriptionToken', 'MIT', address(this));

        tokenInfo[newToken] = TokenInfo({ totalSupply: totalSupply, perMint: perMint, mintedAmount: 0 });

        emit InscriptionDeployed(newToken, symbol, totalSupply, perMint);
        return newToken;
    }

    // authorize upgrade(only owner)
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
