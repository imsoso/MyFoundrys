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

    error AmountMustGreaterThanZero();
    error InsufficientStake();

    event TokenStaked(address indexed user, uint256 amount);
    event TokenUnStaked(address indexed user, uint256 amount);
    event TokenClaimed(address indexed user, uint256 amount);

    constructor(address _esRNTToken, address _RNTToken) {
        esRNTToken = esRNT(_esRNTToken);
        RNTToken = SoToken(_RNTToken);
    }

    // User can stake their RNT to get rewards
    function stake(uint256 amount) external {
        if (amount == 0) {
            revert AmountMustGreaterThanZero();
        }

        StakeInfo storage stakeInfo = stakeInfos[msg.sender];
        stakeInfo.unclaimed += getRewardAmount(msg.sender);
        // Stacked must calculate after getRewardAmount is called
        // because it base on the old staked amount

        stakeInfo.staked += amount;
        stakeInfo.lastUpdateTime = block.timestamp;

        RNTToken.transfer(address(this), amount);

        emit TokenStaked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        if (amount == 0) {
            revert AmountMustGreaterThanZero();
        }
        StakeInfo storage stakeInfo = stakeInfos[msg.sender];
        if (stakeInfo.staked < amount) {
            revert InsufficientStake();
        }

        // We still calculate reward amount for the user
        // because time elapsed before unstake
        stakeInfo.unclaimed += getRewardAmount(msg.sender);

        if (stakeInfo.staked < amount) {
            revert InsufficientStake();
        }
        stakeInfo.staked -= amount;
        stakeInfo.lastUpdateTime = block.timestamp;

        RNTToken.transferFrom(address(this), msg.sender, amount);

        emit TokenUnStaked(msg.sender, amount);
    }

    function claim() external {
        StakeInfo storage stakeInfo = stakeInfos[msg.sender];
        uint256 rewardAmount = stakeInfo.unclaimed;

        if (rewardAmount == 0) {
            revert AmountMustGreaterThanZero();
        }

        stakeInfo.unclaimed = 0;
        stakeInfo.lastUpdateTime = block.timestamp;

        esRNTToken.mint(msg.sender, rewardAmount);

        emit TokenClaimed(msg.sender, rewardAmount);
    }
    // calculate the reward amount for the user
    // user | Staked | Unclaimed| Lastupdatetime|Action
    // Alice|10|0|10:00|Stake
    // Alice|10 + 20 | 0 + 10 * 1/24 = 0.41|11:00|Stake
    // Alice|10 + 20 + 10 | 0.41 + 30 * 2/24 = 2.91|13:00|Stake
    // Alice|10 + 20 + 10 -15 | 2.91 +40* 2/24 = 6.24|15:00|UnStake
    // Alice|10 + 20 + 10 -15 | 0|16:00|Claim
    function getRewardAmount(address user) public view returns (uint256) {
        uint256 timeElapsed = block.timestamp > stakeInfos[user].lastUpdateTime ? block.timestamp - stakeInfos[user].lastUpdateTime : 0;

        uint256 pendingRewards = (stakeInfos[user].staked * timeElapsed) / DAY_IN_SECONDS;
        return pendingRewards;
    }
}
