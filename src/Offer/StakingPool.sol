// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../BaseTokens/BurnableToken.sol';
import '../BaseTokens/ERC20WithPermit.sol';
contract StakingPool {
    esRNT public esRNTToken;
    SoToken public RNTToken;

    uint256 public constant DAY_IN_SECONDS = 86400;

    struct StakeInfo {
        uint256 staked;
        uint256 unclaimed;
        uint256 lastUpdateTime;
    }
    mapping(address => StakeInfo) public stakeInfos;
    constructor(address _esRNTToken, address _RNTToken) {
        esRNTToken = esRNT(_esRNTToken);
        RNTToken = SoToken(_RNTToken);
    }

    // calculate the reward amount for the user
    // user | Staked | Unclaimed| Lastupdatetime|Action
    // Alice|10|0|10:00|Stake
    // Alice|10 + 20 | 0 + 10 * 1/24 = 0.41|11:00|Stake
    // Alice|10 + 20 + 10 | 0.41 + 30 * 2/24 = 2.91|13:00|Stake
    // Alice|10 + 20 + 10 -15 | 2.91 +40* 2/24 = 6.24|15:00|UnStake
    // Alice|10 + 20 + 10 -15 | 0|16:00|Claim
    function getRewardAmount(address user) public view returns (uint256) {
        uint256 pendingRewards = (stakeInfos[user].staked * (block.timestamp - stakeInfos[user].lastUpdateTime)) / DAY_IN_SECONDS;
        return pendingRewards;
    }
