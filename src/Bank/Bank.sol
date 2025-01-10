// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Bank {
    mapping(address => uint256) public balances;
    address[3] public topDepositors;

    address public owner;

    error DepositMustGreaterThanZero();
    error InfufficientBalance();

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        if (msg.value == 0) {
            revert DepositMustGreaterThanZero();
        }

        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);

        updateTop3Depositor(msg.sender);
    }

    // Receive ETH
    receive() external payable {
        deposit();
    }

    modifier onlyOwner() {
        require(msg.sender == address(this), 'Owner only');
        _;
    }

    function withdraw(uint amount) public onlyOwner {
        if (balances[msg.sender] < amount) {
            revert InfufficientBalance();
        }

        payable(owner).transfer(amount);
        balances[msg.sender] -= amount;
        emit Withdraw(amount);
    }

    function updateTop3Depositor(address depositor) private {
        uint newBalance = balances[depositor];
        uint index = 3;
        for (uint i = 0; i < 3; i++) {
            if (newBalance > balances[topDepositors[i]]) {
                index = i;
                break;
            }
        }

        if (index < 3) {
            for (uint i = 2; i > index; i--) {
                topDepositors[i] = topDepositors[i - 1];
            }
            topDepositors[index] = depositor;
        }
    }
}
