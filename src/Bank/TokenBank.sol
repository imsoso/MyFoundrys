// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { SoToken } from '../NFTs/MyToken.sol';

contract TokenBank {
    SoToken token;
    mapping(address => uint256) private balances;

    error AmountGreaterThanZero();

    event Deposit(address indexed user, uint256 amount);

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

    function withdraw() public {}
}
