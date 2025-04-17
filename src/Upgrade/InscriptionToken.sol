// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.28;

// import { ERC20Upgradeable } from '@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol';
import { Initializable } from '@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol';
import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
// import { OwnableUpgradeable } from '@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol';

contract InscriptionToken is Initializable, ERC20, Ownable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name, string memory symbol, address initialOwner) external initializer {
        require(bytes(name()).length == 0, 'Already initialized');
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
