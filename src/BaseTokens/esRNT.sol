// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.28;
contract esRNT {
    struct LockInfo {
        address user;
        uint64 startTime;
        uint256 amount;
    }
    LockInfo[] private _locks;

    constructor() {
        for (uint256 i = 0; i < 11; i++) {
            _locks.push(LockInfo(address(uint160(i + 1)), uint64(block.timestamp * 2 - i), 1e18 * (i + 1)));
        }
    }
}
