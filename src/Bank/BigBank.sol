// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import './Bank.sol';

contract BigBank is Bank {
    address public admin;

    error DepositTooSmall();
    error NotAdmin();
    error IllegalAddress();
    constructor() {
        admin = msg.sender;
    }

    modifier greaterThanOneFinney() {
        if (msg.value <= 0.001 ether) {
            revert DepositTooSmall();
        }
        _;
    }

    function transferAdmin(address newAdmin) external {
        if (msg.sender != admin) {
            revert NotAdmin();
        }

        if (newAdmin == address(0)) {
            revert IllegalAddress();
        }
    
        admin = newAdmin;
        
    }
}
