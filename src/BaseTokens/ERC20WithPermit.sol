// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.28;

import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import { ERC20Permit } from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

contract SoToken is ERC20, Ownable, ERC20Permit {
    constructor(address initialOwner) ERC20('SoToken', 'STK') Ownable(initialOwner) ERC20Permit('SoToken') {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function transferAndCall(address to, uint256 amount, bytes memory data) public returns (bool) {
        bool success = transfer(to, amount);
        if (success && isContract(to)) {
            // Call target contract tokensReceived()
            (success, ) = to.call(abi.encodeWithSignature('tokensReceived(msg.sender, to, amount, data)', msg.sender, to, amount, data));
            require(success, 'tokensReceived fail');
        }

        return true;
    }

    function isContract(address addr) public view returns (bool) {
        return addr.code.length != 0;
    }
}
