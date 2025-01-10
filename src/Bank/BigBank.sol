// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import './Bank.sol';

contract BigBank is Bank {
    error DepositTooSmall();

    modifier greaterThanOneFinney() {
        if (msg.value <= 1 finney) {
            revert DepositTooSmall();
        }
        _;
    }
}
