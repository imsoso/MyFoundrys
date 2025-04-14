// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import 'forge-std/StdUtils.sol';
import '../src/BaseTokens/BurnableToken.sol';
import '../src/BaseTokens/ERC20WithPermit.sol';

contract esRNTTokenTest is Test {
    esRNT public esRNTToken;
    SoToken public RNTToken;

    address public owner;
    address public user;

    uint256 public constant MONTH_IN_SECONDS = 2592000;

    struct LockInfo {
        uint256 amount;
        uint256 lockTime;
    }

    function setUp() public {
        owner = address(this);
        user = vm.addr(1);
        RNTToken = new SoToken(address(this));
        esRNTToken = new esRNT(address(this), address(this), address(RNTToken));
    }

    function testMint() public {
        // Mint tokens to the user
        esRNTToken.mint(user, 100 * 10 ** 18);

        // Check the user's balance
        assertEq(esRNTToken.balanceOf(user), 100 * 10 ** 18);

        // Check the user's LockInfo.amount
        (uint256 amount, uint256 lockTime) = esRNTToken.lockInfos(user, 0);
        LockInfo memory aLock = LockInfo(amount, lockTime);

        uint256 lockAmount = aLock.amount;
        assertEq(lockAmount, 100 * 10 ** 18);
    }

    function testAllClaim() public {
        uint256 amount = 100 * 10 ** 18;
        // Mint tokens to the user
        esRNTToken.mint(user, amount);

        vm.warp(block.timestamp + MONTH_IN_SECONDS);

        deal(address(RNTToken), address(esRNTToken), amount);
        vm.prank(user);
        esRNTToken.claim(amount);

        assertEq(RNTToken.balanceOf(user), amount);
        assertEq(esRNTToken.balanceOf(user), 0);
    }

    function testPartBurnClaim() public {
        uint256 amount = 100 * 10 ** 18;
        // Mint tokens to the user
        esRNTToken.mint(user, amount);

        vm.warp(block.timestamp + MONTH_IN_SECONDS / 2);

        deal(address(RNTToken), address(esRNTToken), amount);
        vm.prank(user);
        esRNTToken.claim(amount);

        assertEq(RNTToken.balanceOf(user), amount / 2);
        assertEq(esRNTToken.balanceOf(user), 0);
    }
}
