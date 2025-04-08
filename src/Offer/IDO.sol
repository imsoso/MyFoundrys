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

    mapping(address => uint256) public balances; // user address -> balance

    error InsuffientFund();
    error ReachMaxFunding();
    error FailedToSendETH();

    modifier onlyActive() {
        require(block.timestamp < deploymentTimestamp + preSaleDuration, 'Project has ended');
        require(currentTotalFunding + msg.value < maxFunding, 'Funding limit reached');
        _;
    }

    modifier onlySuccess() {
        require(currentTotalFunding >= minFunding, 'Funding target not reached');
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Only owner');
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

    function presale() public payable onlyActive {
        if (msg.value < minFunding) {
            revert InsuffientFund();
        }

        if ((balances[msg.sender] - msg.value) > maxFunding) {
            revert ReachMaxFunding();
        }

        balances[msg.sender] += msg.value;
    }

    function claimTokens() public onlySuccess {
        if (balances[msg.sender] == 0) {
            revert InsuffientFund();
        }
        
        uint256 avaliableTokens = balances[msg.sender] / preSalePrice;
        balances[msg.sender] = 0;
        token.transfer(msg.sender, avaliableTokens);
    }

    function withdraw() public onlySuccess onlyOwner {
        uint256 totalEth = address(this).balance;
        uint amountToTeam = totalEth / 10;
        (bool sent, ) = owner.call{ value: amountToTeam }('');
        if (!sent) {
            revert FailedToSendETH();
        }
    }
}
