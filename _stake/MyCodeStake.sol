// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";


import "./log.sol"; 


contract RNT is ERC20{
    constructor() ERC20("RNT", "RNT") {
    }
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
        function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

contract ESRNT is ERC20{
    constructor() ERC20("esRNT", "esRNT") {
    }
        function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
        function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

contract Staking {
    // 首先初始化地址
    RNT public rnt;
    ESRNT public esrnt;

    // 自定义 每秒的奖励 和 锁仓周期；
    uint256 public constant reware = 11820330969267;
    uint256 public constant lock_period = 30 days;

    // 用户质押信息 账号 - 上次更新的时间 - 还没有领取的奖励
    struct UserStake {
        uint256 amount;
        uint256 lastupdateTime;
        uint256 pendingRewards;
    }

    // es用户的锁仓记录 锁仓的数量 - 时间戳
    struct LockRecord {
        uint256 amount;
        uint256 timestamp;
    }

    // 每个地址对应的 质押信息
    mapping(address => UserStake) public stakes;

    // 每个地址对应的锁仓记录
    mapping(address => LockRecord[]) public lockRecords;

    // 质押事件 - 账户 - 数量
    // 解除质押事件 - 账户 - 数量

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Locked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event Redeemed(address indexed user, uint256 esRntAmount, uint256 rntAmount, uint256 burned);

    uint256 public totalStaked;
    

    // 初始化 传入2个TOKEN的地址 然后在mint一些代币给合约地址！
    constructor(address _RNT, address _ESRNT) {
        rnt = RNT(_RNT);
        esrnt = ESRNT(_ESRNT);
        rnt.mint(address(this), 1000000000000000000000000);
        esrnt.mint(address(this), 1000000000000000000000000);
    } 

    // 计算更新用户奖励
    function updateRewards(address user) public{
        // 取出用户的质押信息
        UserStake storage userStake = stakes[user];
        
        
        // 如果用户质押的数量大于0 - 则计算奖励 - 然后把奖励加到用户的待领取奖励里面
        
    
        if(userStake.amount > 0){    
            uint256 PastTime = block.timestamp - userStake.lastupdateTime;
            uint256 rewards = userStake.amount * PastTime * reware / 1 ether;
            userStake.pendingRewards+= rewards;
        }

        // 把最后的更新时间记录
        userStake.lastupdateTime = block.timestamp;

    }


    // 质押函数
    function stake (uint256 amount) public {
        require(amount > 0);
        // 更新数据
        updateRewards(msg.sender);
        // 转账成功才可以更可以更新数据
        require(rnt.transferFrom(msg.sender,address(this), amount));
        stakes[msg.sender].amount += amount;
        totalStaked+= amount;
        emit Staked(msg.sender, amount);
    }

    function Unstake (uint256 amount) public {
        require(amount > 0);
        UserStake storage userStake = stakes[msg.sender];
        // 要大于等于已经质押的数量才可以解除；
        require(userStake.amount >= amount,"Insufficient balance"); 
        updateRewards(msg.sender);

        userStake.amount -= amount;
        totalStaked -= amount;

        rnt.transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }


    function claimRewards() external {
        updateRewards(msg.sender);
        UserStake storage userStake = stakes[msg.sender];
        uint256 rewards = userStake.pendingRewards;
        require(rewards > 0, "No rewards to claim");

        userStake.pendingRewards = 0;
        esrnt.transfer(msg.sender, rewards);
        emit RewardsClaimed(msg.sender, rewards);
        // 首先更新记录
        // 查看领取的奖励 重置为0 在合约转账给用户
    }

    // 用户锁仓esrnt - 并记录锁仓的数量和时间
    function lockEsrnt(uint256 amount) external{

        require(amount > 0);
        require(esrnt.transferFrom(msg.sender, address(this), amount), "Failed to transfer esRNT");

        lockRecords[msg.sender].push(LockRecord(amount, block.timestamp));
        emit Locked(msg.sender, amount);

    }


function redeem(uint256 esRntAmount) external {
    require(esRntAmount > 0, "Amount must be greater than 0");
    LockRecord[] storage records = lockRecords[msg.sender];

    uint256 totalRnt = 0;
    uint256 remaining = esRntAmount;

    // 遍历用户的锁仓记录，计算可释放的 RNT 数量
    for (uint256 i = 0; i < records.length && remaining > 0; i++) {
        if (records[i].amount == 0) continue;

        uint256 amountToRedeem = remaining > records[i].amount ? records[i].amount : remaining;
        uint256 timeElapsed = block.timestamp - records[i].timestamp;
        uint256 releaseRatio = timeElapsed >= lock_period ? 1 ether : (timeElapsed * 1 ether) / lock_period;

        uint256 rntAmount = (amountToRedeem * releaseRatio) / 1 ether;
        totalRnt += rntAmount;
        records[i].amount -= amountToRedeem;
        remaining -= amountToRedeem;
    }
    console.log("amountToRedeem",amountToRedeem);
    console.log("timeElapsed",timeElapsed); 
    console.log("releaseRatio",releaseRatio); 
    console.log("rntAmount",rntAmount); 

    require(totalRnt > 0, "No RNT available to redeem");

    // 由于锁仓时用户的 esRNT 已转到合约，这里从合约地址烧毁
    esrnt.burn(address(this), esRntAmount);
    rnt.transfer(msg.sender, totalRnt);

    // 清理已归零的锁仓记录
    for (uint256 i = records.length; i > 0; i--) {
        if (records[i - 1].amount == 0) {
            records[i - 1] = records[records.length - 1];
            records.pop();
        }
    }

    emit Redeemed(msg.sender, esRntAmount, totalRnt, esRntAmount - totalRnt);
}



    // 查看质押的信息和 未领取的奖励
    function getStakeInfo(address user) external view returns (uint256 staked, uint256 rewards) {
        UserStake memory userStake = stakes[user];
        return (userStake.amount, userStake.pendingRewards);
    }

    function getLockRecords(address user) external view returns (LockRecord[] memory) {
        return lockRecords[user];
    }


    function previewRedeem(address user, uint256 esRntAmount) external view returns (uint256 totalRnt, uint256 totalBurned) {
        LockRecord[] storage records = lockRecords[user];
        uint256 remaining = esRntAmount;
        for (uint256 i = 0; i < records.length && remaining > 0; i++) {
            if (records[i].amount == 0) continue;
            uint256 amountToRedeem = remaining > records[i].amount ? records[i].amount : remaining;
            uint256 timeElapsed = block.timestamp - records[i].timestamp;
            uint256 releaseRatio = timeElapsed >= lock_period ? 1 ether : (timeElapsed * 1 ether) / lock_period;
            uint256 rntAmount = (amountToRedeem * releaseRatio) / 1 ether;
            totalRnt += rntAmount;
            totalBurned += amountToRedeem - rntAmount;
            remaining -= amountToRedeem;
        }
        return (totalRnt, totalBurned);
    }

    function getCurrentTimestamp() external view returns (uint256) {
    return block.timestamp;
}
}