// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

contract TokenWithCallback is ERC20, Ownable {
    constructor(address initialOwner) ERC20('MyTokenCall', 'MTKC') Ownable(initialOwner) {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
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
