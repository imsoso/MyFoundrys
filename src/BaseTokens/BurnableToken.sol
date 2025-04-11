// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.28;

import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import { ERC20Burnable } from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import './ERC20WithPermit.sol';

contract esRNT is ERC20, ERC20Burnable, Ownable {
    SoToken public RNTToken;
    uint256 public constant MONTH_IN_SECONDS = 2592000;

    struct LockInfo {
        uint256 amount;
        uint256 lockTime;
    }
    mapping(address => LockInfo[]) public lockInfos;

    error InsufficientBalance();

    event TokenLocked(address indexed user, uint256 amount, uint256 lockTime);
    event TokenClaimed(address indexed user, uint256 amount, uint256 receivedAmount);

    constructor(address recipient, address initialOwner, address _RNTToken) ERC20('esRNT', 'esRNT') Ownable(initialOwner) {
        RNTToken = SoToken(_RNTToken);
        _mint(recipient, 1000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
        // Add a new lock entry for the recipient with the specified amount and the current timestamp as the lock time
        lockInfos[to].push(
            LockInfo({
                amount: amount, // The amount to lock
                lockTime: block.timestamp // The time at which the lock is created
            })
        );
        emit TokenLocked(to, amount, block.timestamp);
    }

    function claim(uint256 amount) public {
        if (balanceOf(msg.sender) < amount) {
            revert InsufficientBalance();
        }

        uint256 totalUnlocked;

        for (uint256 i = 0; i < lockInfos[msg.sender].length; i++) {
            LockInfo memory aLock = lockInfos[msg.sender][i];
            if (aLock.amount == 0) continue;
            uint256 unlockedAmount = (aLock.amount * (block.timestamp - aLock.lockTime)) / MONTH_IN_SECONDS;
            totalUnlocked += unlockedAmount;
        }
        delete lockInfos[msg.sender];
        RNTToken.transfer(msg.sender, totalUnlocked);
        _burn(msg.sender, amount);

        emit TokenClaimed(msg.sender, amount, totalUnlocked);
    }
}
