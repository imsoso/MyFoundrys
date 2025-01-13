// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
// OriginalBank contract implementing IBank interface
contract OriginalBank is IBank {
    address public owner;
    mapping(address => uint256) private balances;
    address[] public topDepositors;

    // Constructor to set the contract owner
    constructor() {
        owner = msg.sender;
    }

    // Modifier to restrict function access to owner only
    modifier onlyOwner() {
        require(msg.sender == owner, 'Only owner can call this function');
        _;
    }

    // Fallback function to handle direct ETH transfers
    receive() external payable {
        deposit();
    }

    // Deposit function to add funds to the contract
    function deposit() public payable virtual override {
        balances[msg.sender] += msg.value;
        updateTopDepositors(msg.sender);
        emit Deposit(msg.sender, msg.value);
    }

    // Withdraw function to transfer funds to the owner
    function withdraw(uint256 amount) public override onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, 'Contract balance is zero');
        require(amount <= balance, 'Insufficient contract balance');
        payable(owner).transfer(amount);
        emit Withdrawal(owner, amount);
    }

    // Internal function to update the list of top depositors
    function updateTopDepositors(address depositor) internal {
        bool exists = false;
        for (uint256 i = 0; i < topDepositors.length; i++) {
            if (topDepositors[i] == depositor) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            topDepositors.push(depositor);
        }

        // Sort depositors based on their balance
        for (uint256 i = 0; i < topDepositors.length; i++) {
            for (uint256 j = i + 1; j < topDepositors.length; j++) {
                if (balances[topDepositors[i]] < balances[topDepositors[j]]) {
                    address temp = topDepositors[i];
                    topDepositors[i] = topDepositors[j];
                    topDepositors[j] = temp;
                }
            }
        }

        // Keep only the top 3 depositors
        if (topDepositors.length > 3) {
            topDepositors.pop();
        }
    }

    // Get balance for a specific address
    function getBalance(address addr) public view override returns (uint256) {
        return balances[addr];
    }

    // Get the list of top depositors
    function getTopDepositors() public view override returns (address[] memory) {
        return topDepositors;
    }
}
