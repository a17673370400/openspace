// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;


contract SafeWallet {
    address [] public owners;
    uint256 public required;

    // 定义 所有人的地址
    // 定义 需要确认的数量


    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 ConfirmNum;
    }

    // 定义结构体
    // 地址 -> 交易数量 -> 交易data -> 是否确认 -> 多签人数的确认数量

    Transaction [] public transactions;
    // 定义所有交易数组

    // 交易ID => (持有人 => 是否已确认)
    // 地址 -> 是否为持有人
    mapping(uint256 => mapping(address => bool)) public Confirm;
    mapping(address => bool) public isOwner;



    receive () payable external{
        emit Deposit(msg.sender,msg.value,address(this).balance);
    }
    // 存款函数



    // 事件声明
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(address indexed owner, uint256 indexed txId, address indexed to, uint256 value, bytes data);
    event ConfirmTransaction(address indexed owner, uint256 indexed txId);
    event ExecuteTransaction(address indexed executor, uint256 indexed txId);
    event RevokeConfirmation(address indexed owner, uint256 indexed txId);


    constructor(address [] memory _address,uint256 _required){
        require(_address.length > 0,"least one owner");
        require(_required > 0 && _required <= _address.length,"_required is invalid");


        for(uint256 i = 0;i< _address.length;i++){
            address owner = _address[i];
            require(owner != address(0),"address is invalid");
            require(!isOwner[owner],"owner is not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;  // 添加此行
    }

    // 初始化函数  判断 是否为唯一地址 确认数量书否异常 判断是否已经存入该地址为所有人 

    function SbTransaction (address _to,uint256 _value, bytes memory _data) public onlyOwner {
        uint256 txId = transactions.length;
        transactions.push(Transaction({
            to:_to,
            value:_value,
            data:_data,
            executed:false,
            ConfirmNum:0
        }));
        emit SubmitTransaction(msg.sender, txId, _to, _value, _data);
    }

    // 提交交易函数 -> 添加交易结构体 -> 交易ID -> 交易数组 -> 交易结构体 -> 交易ID -> 交易to -> 交易value -> 交易data -> 交易是否执行 -> 交易确认数量

    function SBSignature(uint256 _txId) public onlyOwner txExists(_txId) notExecuted(_txId) notConfirmed(_txId){
        Transaction storage transaction = transactions[_txId];
        transaction.ConfirmNum += 1;
        Confirm[_txId][msg.sender] =true;
        emit ConfirmTransaction(msg.sender,_txId);
    }

    // 签名函数 -> 判断是否为持有人 -> 判断交易是否存在 -> 判断交易是否执行 -> 判断是否已经确认过


    function ExecuteTrade(uint256 _txId) public txExists(_txId) notExecuted(_txId) {
        Transaction storage transaction = transactions[_txId];

        require(transaction.ConfirmNum >= required,"not enough confirmations");
        transaction.executed = true;
        (bool success,) = transaction.to.call{value:transaction.value}(transaction.data);
        require(success,"Transaction failed");
        emit ExecuteTransaction(msg.sender,_txId);
    }

    // 执行交易函数 -> 判断交易是否存在 -> 判断交易是否执行 -> 判断是否已经确认过 -> 判断确认数量是否大于等于需要确认数量 -> 执行交易 -> 判断是否执行成功 -> 事件
    function getTransaction() public view returns(uint256){
        return transactions.length;
    }
    // 获取所有交易数量


    function getTransaction(uint256 _txId) public view returns(
        address to,
        uint256 value,
        bytes memory data,
        bool executed,
        uint256 ConfirmNum
    ) {
        Transaction storage txn = transactions[_txId];
        return (txn.to, txn.value, txn.data, txn.executed, txn.ConfirmNum);
    }


    // 获取交易详情 -> 交易ID -> 交易结构体 -> 交易to -> 交易value -> 交易data -> 交易是否执行 -> 交易确认数量


    modifier onlyOwner() {
        require(isOwner[msg.sender],"only owner");
        _;
    }

        // 修饰符：交易必须存在
    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "Transaction does not exist");
        _;
    }
    
    // 修饰符：交易未执行
    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "Transaction already executed");
        _;
    }
    
    // 修饰符：交易未被该持有人确认过
    modifier notConfirmed(uint256 _txId) {
        require(!Confirm[_txId][msg.sender], "Transaction already confirmed");
        _;
    }
}