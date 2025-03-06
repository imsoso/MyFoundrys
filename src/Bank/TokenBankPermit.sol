// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { SoToken } from '../BaseTokens/ERC20WithPermit.sol';

contract TokenBankPermit {
    SoToken token;
    mapping(address => uint256) public balances;

    error AmountGreaterThanZero();
    error InfufficientBalance();

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _token) {
        token = SoToken(_token);
    }
    function deposit(uint amount) public {
        if (amount == 0) {
            revert AmountGreaterThanZero();
        }

        token.transfer(address(this), amount);
        balances[msg.sender] += amount;

        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint amount) public {
        if (balances[msg.sender] < amount) {
            revert InfufficientBalance();
        }

        token.transfer(msg.sender, amount);
        balances[msg.sender] -= amount;

        emit Withdraw(msg.sender, amount);
    }

    function tokenReceived(address from, uint256 amount) public {
        balances[from] += amount;
    }
}
