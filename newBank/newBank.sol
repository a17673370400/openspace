// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 定义接口
interface Ibank{
    function deposit() external payable;
    function withdraw() external;
}

contract Bank is Ibank {
    address public admin;
    address[3] public topDepositors;
    uint256[3] public topDeposits;

    mapping(address => uint256) public balances;

    event Deposit(address indexed user,uint256 amount);
    event Withdraw(address indexed admin,uint256 amount);
    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);

    constructor() {
        admin = msg.sender; // 初始管理员
    }

    function deposit () public payable virtual override {
        require(msg.value > 0,"DepositValue is low");
        balances[msg.sender] += msg.value;
        _updateTopDepositors(msg.sender,balances[msg.sender]);
        emit Deposit(msg.sender,msg.value);
    }


    function _updateTopDepositors(address user, uint256 amount) internal {
        for (uint256 i = 0; i < 3; i++) {
            if (amount > topDeposits[i]) {
                for (uint256 j = 2; j > i; j--) {
                    topDepositors[j] = topDepositors[j - 1];
                    topDeposits[j] = topDeposits[j - 1];
                }
                topDepositors[i] = user;
                topDeposits[i] = amount;
                break;
            }
        }
    }

    function checkBanlance() public view returns(uint256){
        return balances[msg.sender];
    }

    function withdraw() public virtual override{
        require(msg.sender == admin,"not admin");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available");
        payable(admin).transfer(balance);
        emit Withdraw (msg.sender,balance);
    }

    function getTop() public view returns(address[3] memory,uint[3] memory) {
        return (topDepositors,topDeposits);
    }
}


contract bigBank is Bank {
    modifier bigDeposit() {
        require(msg.value > 0.001 ether,"eth to low");
        _;
    }

    function deposit() public payable virtual override bigDeposit{
        balances[msg.sender] += msg.value;
        _updateTopDepositors(msg.sender,msg.value);
        emit Deposit(msg.sender,msg.value);
    }

    function transferAdmin(address _newadmin) public {
        require(msg.sender == admin,"not admin");
        emit AdminTransferred(admin, _newadmin);
        admin = _newadmin;
    }


}

contract Admin {
    address public owner;
    address public bigBankAddress;

    event AdminWithdraw(address indexed bank, uint256 amount);

    
    constructor(address _bigBank){
        bigBankAddress = _bigBank;
        owner = msg.sender;
    }



    function adminWithdraw(Ibank bank) public {
        require(msg.sender == owner,"not owner");
        bank.withdraw();
        emit AdminWithdraw(address(bank), address(this).balance);
    }


    receive() external payable {}

    
    function  getBalance() public view returns(uint256){
        return address(this).balance;
    }
}