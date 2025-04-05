// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev A simple staking contract with inefficient gas implementation
 */
error ZeroAmount();
error NotEnoughStaked();

event Staked(address indexed user, uint256 amount);
event Withdrawn(address indexed user, uint256 amount);
event RewardPaid(address indexed user, uint256 reward);

contract StakingContract {
    address private immutable STAKING_TOKEN;
    uint256 private immutable REWARD_RATE = 100;

    struct UserInfo {
        uint256 stakedAmount;
        uint256 lastUpdateBlock;
        uint256 rewardsAccumulated;
    }

    mapping(address => UserInfo) public userInfo;

    constructor(address _stakingToken, uint256 _rewardRate) {
        STAKING_TOKEN = _stakingToken;
        REWARD_RATE = _rewardRate;
    }

    function stake(uint256 amount) external {
        if(amount == 0) revert ZeroAmount();

        UserInfo storage user = userInfo[msg.sender];

        _updateReward(user);

        IERC20(STAKING_TOKEN).transferFrom(msg.sender, address(this), amount);

        userInfo[msg.sender].stakedAmount += amount;

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        if(amount == 0) revert ZeroAmount();
        UserInfo storage user = userInfo[msg.sender];

        if (user.stakedAmount < amount) revert NotEnoughStaked();

        _updateReward(user);

        user.stakedAmount -= amount;
        IERC20(STAKING_TOKEN).transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function claimReward() external {
        UserInfo storage user = userInfo[msg.sender];
        _updateReward(user);

        uint256 reward = user.rewardsAccumulated;
        if (reward > 0) {
            user.rewardsAccumulated = 0;
            IERC20(STAKING_TOKEN).transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function _updateReward(UserInfo storage user) private {

        if (user.stakedAmount > 0) {
            user.rewardsAccumulated += _calculateNewRewards(user.lastUpdateBlock, user.stakedAmount);
        }

        user.lastUpdateBlock = block.number;
    }

    function _calculateNewRewards(uint256 lastUpdateBlock, uint256 stakedAmount) private view returns (uint256) {
        uint256 blocksSinceLastUpdate = block.number - lastUpdateBlock;
        return (stakedAmount * REWARD_RATE * blocksSinceLastUpdate) / 1e18;
    }

    function pendingReward(address account) external view returns (uint256) {
        UserInfo storage user = userInfo[account];

        uint256 pending = user.rewardsAccumulated;

        if (user.stakedAmount > 0) {
            pending += _calculateNewRewards(user.lastUpdateBlock, user.stakedAmount);
        }

        return pending;
    }
}
