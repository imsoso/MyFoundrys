// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IBank {
    /**
     * @dev withdraw balance from Bank to Admin
     *
     * Emits a {Withdraw} event.
     */
    function withdraw(uint amount) external;
}
