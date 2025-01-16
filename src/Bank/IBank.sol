// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
interface IBank {
    // Event definitions
    event Withdrawal(address indexed to, uint256 amount);
    event Deposit(address indexed from, uint256 amount);

    // Function definitions to be implemented
    // Getter function for public state variable
    function owner() external view returns (address);

    // Deposit function
    function deposit() external payable;

    /**
     * @dev withdraw balance from Bank to Admin
     *
     * Emits a {Withdraw} event.
     */
    function withdraw(uint256 amount) external;
    // Get balance for a specific address
    function getBalance(address addr) external view returns (uint256);

    // Get top depositors
    function getTopDepositors() external view returns (address[] memory);
}
