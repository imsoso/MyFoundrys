// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract MyWallet {
    string public name;
    mapping(address => bool) private approved;
    address public owner;

    modifier auth() {
        // temp variable
        address currentOwner;
        assembly {
            currentOwner := sload(2)
        }
        require(msg.sender == currentOwner, 'Not authorized');
        _;
    }

    constructor(string memory _name) {
        name = _name;
        assembly {
            sstore(2, caller())
        }
    }

    function transferOwernship(address _addr) external auth {
        require(_addr != address(0), 'New owner is the zero address');
        require(owner != _addr, 'New owner is the same as the old owner');
        assembly {
            sstore(2, _addr)
        }
    }
}
