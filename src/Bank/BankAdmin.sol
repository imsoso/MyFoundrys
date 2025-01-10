// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import { IBank } from './IBank.sol';
contract Admin {
    address owner;
    function adminWithdraw(IBank bank) public {}
}
