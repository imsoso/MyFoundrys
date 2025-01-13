// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import './Bank.sol';

contract BigBank is Bank {
    address public admin;

    error DepositTooSmall();
    error NotAdmin();
    error IllegalAddress();

    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);
    constructor() {
        admin = msg.sender;
    }

    modifier greaterThanOneFinney() {
        if (msg.value <= 0.001 ether) {
            revert DepositTooSmall();
        }
        _;
    }
    // Override the deposit function from the Bank contract
    function deposit() public payable virtual override greaterThanOneFinney {
        super.deposit();
    }

    function transferAdmin(address newAdmin) external {
        if (msg.sender != admin) {
            revert NotAdmin();
        }

        if (newAdmin == address(0)) {
            revert IllegalAddress();
        }

        admin = newAdmin;
        emit AdminTransferred(admin, newAdmin);
    }
}
