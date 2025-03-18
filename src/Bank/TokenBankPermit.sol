// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { SoToken } from '../BaseTokens/ERC20WithPermit.sol';
import { ISignatureTransfer } from 'permit2/interfaces/ISignatureTransfer.sol';

contract TokenBank {
    SoToken token;
    mapping(address => uint256) public balances;

    ISignatureTransfer public immutable permit2;

    error AmountGreaterThanZero();
    error InfufficientBalance();

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _token, address _permit2) {
        token = SoToken(_token);
        permit2 = ISignatureTransfer(_permit2);
    }

    function deposit(uint amount) public {
        if (amount == 0) {
            revert AmountGreaterThanZero();
        }

        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, 'Token transfer failed');

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

    function permitDeposit(uint amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        token.permit(msg.sender, address(this), amount, deadline, v, r, s);
        deposit(amount);
        emit Deposit(msg.sender, amount);
    }
}
