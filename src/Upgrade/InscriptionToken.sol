// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.28;

import { ERC20Upgradeable } from '@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol';
import { OwnableUpgradeable } from '@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol';
import { Initializable } from '@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol';

contract InscriptionToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    function initialize(string memory name, string memory symbol, address initialOwner) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init(initialOwner);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
