// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import '../src/Offer/IDO.sol';
import '../src/BaseTokens/ERC20WithPermit.sol';

contract MyIDOTest is Test {
    MyIDO public myIDO;
    SoToken public token;

    address public ownerAccount;
    address public contributorAlice;
    address public contributorBob;

    function setUp() public {
        token = new SoToken(address(this));
        myIDO = new MyIDO(token, 0.0001 ether, 100 ether, 200 ether, 1 weeks, 1000000);
        // transfer all mint token to IDO contract
        token.transfer(address(myIDO), token.balanceOf(address(this)));

        contributorAlice = makeAddr('Alice');
        contributorBob = makeAddr('Bob');
    }

    function testContributeSucceed() public {
        vm.deal(contributorAlice, 100 ether);
        uint256 IDOBalance = 0.01 ether;

        vm.prank(contributorAlice);
        myIDO.presale{ value: IDOBalance }();
        uint256 aliceContribution = myIDO.balances(contributorAlice);

        assertEq(IDOBalance, aliceContribution, 'Incorrect funding amount');
    }

    function testClaimTokens() public {
        vm.deal(contributorAlice, 1000 ether);
        vm.startPrank(contributorAlice);
        myIDO.presale{ value: 100 ether }();

        myIDO.claimTokens();
        uint256 aliceTokenBalance = token.balanceOf(contributorAlice);
        assertEq(aliceTokenBalance, 1000000, 'Alice token balance should be greater than 0');
        vm.stopPrank();
    }

    function testRefund() public {
        vm.deal(contributorAlice, 1000 ether);
        vm.startPrank(contributorAlice);
        myIDO.presale{ value: 1 ether }();

        myIDO.refund();
        uint256 aliceTokenBalance = token.balanceOf(contributorAlice);
        assertEq(aliceTokenBalance, 0, 'Alice token balance should be 0');

        uint256 aliceEthBalance = contributorAlice.balance;
        assertEq(aliceEthBalance, 1000 ether, "Alice's eth balance should be 1000");
        vm.stopPrank();
    }

    function testRefundFailed() public {
        vm.deal(contributorAlice, 1000 ether);
        vm.prank(contributorAlice);
        myIDO.presale{ value: 100 ether }();

        vm.expectRevert('Cannot do it, Funding target reached');
        myIDO.refund();
    }

    function testTeamWithdraw() public payable {
        vm.deal(contributorAlice, 1000 ether);
        vm.prank(contributorAlice);
        myIDO.presale{ value: 100 ether }();

        vm.deal(address(this), 0);
        myIDO.withdraw();
        uint256 teamEthBalance = address(this).balance;
        assertEq(teamEthBalance, 10 ether, "Team's eth balance should be 10");
    }

    receive() external payable {}
}
