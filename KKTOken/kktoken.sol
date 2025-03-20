// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract KKtoken is ERC20{
    constructor() ERC20("kktoken", "KK") {
    }
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// Staking 接口
interface IStaking {
    function stake() external payable;
    function unstake(uint256 amount) external;
    function claim() external;
    function balanceOf(address account) external view returns (uint256);
    function earned(address account) external view returns (uint256);
}

// Staking 合约
contract Staking is IStaking {
    KKtoken public kktoken;
    uint256 public constant REWARD_PRE_BLOCK = 10 * 10**18;
    uint256 public lastRewarBlock;
    uint256 public totalStaked;
    uint256 public rewardPerTokenStored;


    struct Userinfo {
        uint256 amount;
        uint256 reward;
    }

    mapping(address => Userinfo) public userinfo;

    event Staked(address indexed user,uint256 amount);
    event Unstaked(address indexed user,uint256 amount);
    event Claimed(address indexed user,uint256 amount);

    constructor(address _kktoken){
        kktoken = KKtoken(_kktoken);
        lastRewarBlock = block.number;
    }

    function updateReward() internal{ 
        if(block.number <= lastRewarBlock || totalStaked == 0){
            lastRewarBlock = block.number;
            return;
        }
        // 先看看过了多少个区块 - 然后算算总的区块奖励 - 然后算算每个人的奖励
        uint256 blocks = block.number - lastRewarBlock;
        uint256 reward = blocks * REWARD_PRE_BLOCK;
        rewardPerTokenStored += (reward * 1e18) / totalStaked;
        lastRewarBlock = block.number;
    }

    function stake() public payable override{
        require(msg.value>0);
        updateReward();
        updateUserReward(msg.sender);

        Userinfo storage user = userinfo[msg.sender];
        user.amount += msg.value;
        totalStaked += msg.value;

        emit Staked(msg.sender, msg.value);
    }

    function updateUserReward(address account) internal{
        Userinfo storage user = userinfo[account];
        if(user.amount > 0 ){
            uint256 pending = (user.amount * rewardPerTokenStored) / 1e18- user.reward;;
            if(pending > 0){
                kktoken.mint(account, pending);
            }
        }

        user.reward = (user.amount * rewardPerTokenStored) / 1e18;
    }


    function unstake(uint256 amount)external override{
        Userinfo storage user = userinfo[msg.sender];

        require(amount > 0);

        require(user.amount >= amount);

        updateReward();
        updateUserReward(msg.sender);


        user.amount -= amount;
        totalStaked -= amount;

        (bool success,) = msg.sender.call{value:amount}("");
        require(success,"Transfer failed");

        emit Unstaked(msg.sender, amount);
    }

    function claim() external override{
        updateReward();
        updateUserReward(msg.sender);
        emit Claimed(msg.sender, userinfo[msg.sender].reward);
    }
    
    function balanceOf(address account) external view override returns (uint256) {
        return userinfo[account].amount;
    }
    

    function earned(address account) external view returns (uint256) {
        Userinfo memory user = userinfo[account];
        uint256 rewardPerToken = rewardPerTokenStored;
        
        if(block.number > lastRewarBlock && totalStaked != 0){
            uint256 blocks = block.number - lastRewarBlock;
            uint256 reward = blocks * REWARD_PRE_BLOCK;
            rewardPerToken += (reward * 1e18) / totalStaked;
        }

        return(user.amount * rewardPerToken) / 1e18 - user.reward;

    }



    receive() external payable {
        stake();
    }
}