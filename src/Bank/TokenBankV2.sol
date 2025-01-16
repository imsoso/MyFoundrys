// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import './TokenBank.sol';
import { TokenWithCallback } from '../BaseTokens/TokenWithCallback.sol';

contract TokenBankV2 is TokenBank {
    constructor(SoToken _token) TokenBank(address(_token)) {
        token = _token;
    }

    function tokenReceived(address from, uint256 amount) public {
        balances[from] += amount;
    }
}
