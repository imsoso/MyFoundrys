// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import '../src/BaseTokens/ERC20WithPermit.sol';
import '../src/BaseTokens/BurnableToken.sol';
import '../src/Offer/StakingPool.sol';

contract StakingPoolTest is Test {
    esRNT public esRNTToken;
    SoToken public RNTToken;
    address public owner;
    address public user;
    StakingPool public stakingPool;

    uint256 public constant DAY_IN_SECONDS = 86400;

    struct StakeInfo {
        uint256 staked;
        uint256 unclaimed;
        uint256 lastUpdateTime;
    }

    function setUp() public {
        owner = address(this);
        user = makeAddr('user');

        RNTToken = new SoToken(owner);
        esRNTToken = new esRNT(owner, owner, address(RNTToken));
        stakingPool = new StakingPool(address(esRNTToken), address(RNTToken));

        // Owner grants mint permission to a trusted address
        esRNTToken.grantRole(esRNTToken.MINTER_ROLE(), address(stakingPool));
        // Mint tokens to the user
        RNTToken.mint(user, 100 * 10 ** 18);
    }

    function testStake() public {
        uint amount = 100 * 10 ** 18;
        // User transfers tokens directly to the pool first
        vm.prank(user);
        RNTToken.approve(address(stakingPool), amount);

        // Then user calls stake to record the action
        vm.prank(user); // Prank again as transfer consumes the prank
        stakingPool.stake(amount);

        // Check the user's balance
        assertEq(RNTToken.balanceOf(user), 0);

        // Check the StakingPool's balance

        (uint256 staked, , ) = stakingPool.stakeInfos(user);

        assertEq(staked, amount);
    }

    function testUnstake() public {
        uint amount = 100 * 10 ** 18;
        // User transfers tokens directly to the pool first
        vm.prank(user);
        RNTToken.approve(address(stakingPool), amount);

        // Then user calls stake to record the action
        vm.startPrank(user); // Prank again as transfer consumes the prank
        stakingPool.stake(amount);

        // Unstake the tokens
        stakingPool.unstake(amount);
        vm.stopPrank();

        // Check the User's balance
        assertEq(RNTToken.balanceOf(address(user)), amount);

        // Check the StakingPool's balance
        assertEq(RNTToken.balanceOf(address(stakingPool)), 0);

        // Check the user's stake info
        (uint256 staked, , ) = stakingPool.stakeInfos(user);
        assertEq(staked, 0);
    }

    function testClaimReward() public {
        // Stake
        uint amount = 100 * 10 ** 18;
        vm.startPrank(user);
        RNTToken.approve(address(stakingPool), amount);
        stakingPool.stake(amount);
        vm.stopPrank();

        // 2 days later
        vm.warp(block.timestamp + DAY_IN_SECONDS * 2);

        // Claim the reward
        vm.prank(user);
        stakingPool.claim();

        // Check the user's balance
        assertEq(esRNTToken.balanceOf(address(user)), 200 * 10 ** 18);

        // Check the StakingPool's balance
        // assertEq(RNTToken.balanceOf(address(esRNTToken)), 0);
    }
}
