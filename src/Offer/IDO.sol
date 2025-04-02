// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MyIDO {
    address public owner;

    ERC20 public token;
    uint256 preSalePrice; // Token price in ETH
    uint256 minFunding; // Fundraising target in ETH
    uint256 maxFunding; // Maximum fundraising amount in ETH
    uint256 public currentTotalFunding;
    uint256 totalSupply;

    uint256 deploymentTimestamp; // Use to record contract deployment time
    uint256 preSaleDuration; // Campaign duration in seconds

    modifier onlyActive() {
        require(block.timestamp < deploymentTimestamp + preSaleDuration, 'Project has ended');
        require(currentTotalFunding + msg.value < maxFunding, 'Funding limit reached');
        _;
    }
    constructor(
        ERC20 _token,
        uint256 _preSalePrice,
        uint256 _minFunding,
        uint256 _maxFunding,
        uint256 _preSaleDuration,
        uint256 _totalSupply
    ) {
        owner = msg.sender;
        token = _token;
        preSalePrice = _preSalePrice;
        minFunding = _minFunding;
        maxFunding = _maxFunding;
        deploymentTimestamp = block.timestamp;
        preSaleDuration = _preSaleDuration;
        totalSupply = _totalSupply;
    }
}
