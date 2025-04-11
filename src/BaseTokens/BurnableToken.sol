// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.28;

import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import { ERC20Burnable } from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import './ERC20WithPermit.sol';

contract esRNT is ERC20, ERC20Burnable, Ownable {
    SoToken public RNTToken;
    constructor(address recipient, address initialOwner, address _RNTToken) ERC20('esRNT', 'esRNT') Ownable(initialOwner) {
        RNTToken = SoToken(_RNTToken);
        _mint(recipient, 1000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
