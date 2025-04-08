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
    uint256 minContribution = 0.01 ether;
    uint256 maxContribution = 0.1 ether;

    uint256 deploymentTimestamp; // Use to record contract deployment time
    uint256 preSaleDuration; // Campaign duration in seconds

    mapping(address => uint256) public balances; // user address -> balance

    error InsuffientFund();
    error FailedToSendETH();

    // Event emitted when a user contributes to a campaign
    event Presale(address indexed user, uint256 amount);
    // Event emitted when a user claims their tokens
    event TokenClaim(address indexed user, ERC20 token, uint256 amount);
    event Refund(address indexed user, uint256 amount);
    event TeamWithdrawFunds(address indexed user, uint256 amount);

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

    modifier onlyFailed() {
        require(currentTotalFunding < minFunding, 'Cannot do it, Funding target reached');
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
        if (msg.value < minContribution) {
            revert InsuffientFund();
        }

        balances[msg.sender] += msg.value;
        currentTotalFunding += msg.value;

        emit Presale(msg.sender, msg.value);
    }

    function claimTokens() public onlySuccess {
        if (balances[msg.sender] == 0) {
            revert InsuffientFund();
        }

        uint256 avaliableTokens = balances[msg.sender] / preSalePrice;
        balances[msg.sender] = 0;
        token.transfer(msg.sender, avaliableTokens);

        emit TokenClaim(msg.sender, token, avaliableTokens);
    }

    function withdraw() public onlySuccess onlyOwner {
        uint256 totalEth = address(this).balance;
        uint amountToTeam = totalEth / 10;
        (bool sent, ) = owner.call{ value: amountToTeam }('');
        if (!sent) {
            revert FailedToSendETH();
        }

        emit TeamWithdrawFunds(msg.sender, amountToTeam);
    }

    function refund() public onlyFailed {
        if (balances[msg.sender] == 0) {
            revert InsuffientFund();
        }

        uint amountToRefund = balances[msg.sender];
        (bool sent, ) = msg.sender.call{ value: amountToRefund }('');
        if (!sent) {
            revert FailedToSendETH();
        }
        balances[msg.sender] = 0;

        emit Refund(msg.sender, amountToRefund);
    }
}
