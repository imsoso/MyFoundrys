// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.28;
contract esRNT {
    struct LockInfo {
        address user; // 20 bytes
        uint64 startTime; // slot A: user（20 bytes）+ startTime（8 bytes）
        uint256 amount; // slot B: amount（uint256）
    }
    LockInfo[] private _locks; // _locks.length : slot 0, _locks[i] start from  slot keccak256(0)

    constructor() {
        for (uint256 i = 0; i < 11; i++) {
            _locks.push(LockInfo(address(uint160(i + 1)), uint64(block.timestamp * 2 - i), 1e18 * (i + 1)));
        }
    }
}
