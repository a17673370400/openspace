// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract bank {
    address public admin;
    address[3] public topDepositors;
    uint[3] public topDeposits;

    constructor() {
        admin = msg.sender; // 部署者即为管理员
    }

    mapping(address => uint256) public balances;

    function deposit() public payable virtual{
        balances[msg.sender] += msg.value;
        upTop3(msg.sender, balances[msg.sender]);
    }

    function upTop3(address user, uint256 amount) internal {
    for (uint i = 0; i < 3; i++) {  
        if (amount > topDeposits[i]) {  
            // **将当前排名后的用户往后移动**
            for (uint j = 2; j > i; j--) {  
                topDepositors[j] = topDepositors[j - 1];  
                topDeposits[j] = topDeposits[j - 1];  
            }
            // **插入新存款用户**
            topDepositors[i] = user;
            topDeposits[i] = amount;
            break;  // **找到正确位置后退出循环**
        }
    }

    }
    // 用户存款金额
    function checkBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
    // 体现方法
    function withdraw() public {
        require(msg.sender == admin, "not Admin");
        payable(admin).transfer(address(this).balance);
    }

    // 查看前3
    function getTop() public view returns (address[3] memory, uint256[3] memory){
        return (topDepositors, topDeposits);
    }

}


contract bigBank is bank{

    constructor(address _administrator) {
        admin = _administrator;
    }


    modifier bigDeposit (){
        if(msg.value < 0.001 ether){
            revert('Low Value ');
        }
        _;
    }

    function deposit() public payable override bigDeposit {
            balances[msg.sender] += msg.value;
            upTop3(msg.sender, balances[msg.sender]);
    }

    function xiugaiadmin(address _address) public {
        if(msg.sender != admin){
            revert('notadmin');
        }
        admin = _address;
    }

}

contract Admin {

}