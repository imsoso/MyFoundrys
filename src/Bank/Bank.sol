// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Bank {
    mapping(address => uint256) public balances;

    error DepositMustGreaterTHanZero();

    event Deposit(address indexed user, uint256 amount);

    constructor() {}
    function deposit() public payable {
        if (msg.value == 0) {
            revert DepositMustGreaterTHanZero();
        }

        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // Receive ETH
    receive() external payable {
        deposit();
    }

    function withdraw() public {}
    function top3Depositor() public view returns (address) {}
}
