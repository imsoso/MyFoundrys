// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test, console } from 'forge-std/Test.sol';
import { esRNT } from './SimpleEsRNT.sol';

/* 
// Contract to read
contract esRNT {
    struct LockInfo {
        address user; // 20 bytes
        uint64 startTime; // 8 bytes
        uint256 amount;// 32 bytes
    }
    LockInfo[] private _locks;

    constructor() {
        for (uint256 i = 0; i < 11; i++) {
        _locks.push(LockInfo(address(uint160(i+1)), uint64(block.timestamp * 2 - i), 1e18 * (i + 1)));
        }
    }
}
*/
contract MyESRNTTest is Test {
    esRNT public esRNTContract;

    function setUp() public {
        vm.warp(1000); // set block.timestamp = 1000
        esRNTContract = new esRNT();
    }

    function testReadLocks() public view {
        uint256 initSlot = 0;

        // The array is stored at the slot determined by:
        bytes32 baseSlot = keccak256(abi.encode(initSlot));

        for (uint256 i = 0; i < 11; i++) {
            // LockInfo struct need  20 + 8 + 32 = 60 bytes, so we need 2 slots
            uint256 slotCount = 2;
            uint256 structBaseSlot = uint256(baseSlot) + (i * slotCount);

            // load slot0 with:user + startTime, 28 bytes
            bytes32 slot0Data = vm.load(address(esRNTContract), bytes32(structBaseSlot));

            // address user has 160 bits,from low byte to high
            address user = address(uint160(uint256(slot0Data)));
            // uint64 startTime has 64 bits,from 160 bytes to 224 bytes
            uint64 startTime = uint64(uint256(slot0Data) >> 160);

            // load slot1 with:amount, 32 bytes
            bytes32 slot1Data = vm.load(address(esRNTContract), bytes32(structBaseSlot + slotCount - 1));

            // uint256 amount has 256 bits
            uint256 amount = uint256(slot1Data);

            // Log as required:
            console.log('Lock', i);
            console.log('User:', user);
            console.log('StartTime:', startTime);
            console.log('Amount:', amount);
            console.log('----------------');
        }
    }
}
