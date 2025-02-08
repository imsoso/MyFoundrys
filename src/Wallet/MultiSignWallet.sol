// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract MultiSignWallet {
    // List of multi-signature owners
    address[] public signers;
    // Signature threshold
    uint public threshold;

    constructor(address[] memory _signers, uint _threshold) {
        signers = _signers;
        threshold = _threshold;
    }
}
