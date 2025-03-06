// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from 'forge-std/Test.sol';
import { TokenBank } from '../src/Bank/TokenBankPermit.sol';
import '../src/BaseTokens/ERC20WithPermit.sol';

contract TokenBankTest is Test {
    TokenBank public aTokenBank;
    SoToken public aToken;

    address public owner;
    address seller = makeAddr('seller');
    address buyer = makeAddr('buyer');

    function setUp() public {
        owner = address(this);
        aToken = new SoToken(owner, owner);
    }

    function test_deposit_succeed() public {}
}
