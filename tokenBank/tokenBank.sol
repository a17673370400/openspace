// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract BaseERC20 {
    string public name = "BaseERC20"; 
    string public symbol = "BERC20"; 
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * 10 ** 18; 

    mapping (address => uint256) balances; 

    mapping (address => mapping (address => uint256)) allowances; 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor()  {
        // write your code here
        // set name,symbol,decimals,totalSupply

        balances[msg.sender] = totalSupply;  
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(balances[msg.sender] >= _value,"ERC20: transfer amount exceeds balance");
        balances[msg.sender] -= _value;
        balances[_to] +=  _value;
        emit Transfer(msg.sender, _to, _value);  
        return true;   
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(allowances[_from][msg.sender] >= _value,"ERC20: transfer amount exceeds allowance");

        require(balances[_from] >= _value,"ERC20: transfer amount exceeds balance");

        
        allowances[_from][msg.sender] -= _value;

        balances[_from] -= _value;
        balances[_to] += _value;        
        

        emit Transfer(_from, _to, _value); 
        return true; 
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        // write your code here

        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {   
        // write your code here     
        return allowances[_owner][_spender];

    }
} 


contract TokenBank {
    IERC20 public token;

    mapping(address => uint256) public balances;
    event depositLog (address _address,uint256 value);
    event withdrawLog (address _address,uint256 value);

    constructor(address _tokenaddress){
        token = IERC20(_tokenaddress);
    }

    function deposit(uint256 _value) public {
        require(_value > 0,"value to low");
        
        require(token.allowance(msg.sender, address(this)) >= _value,"apprpve tokenbank first");
        
        require(token.balanceOf(msg.sender) >= _value, "Insufficient token balance");


        require(token.transferFrom(msg.sender, address(this), _value),"transfer failed");
        balances[msg.sender] += _value;
        emit depositLog(msg.sender,_value);

    }



    function withdraw(uint256 _value) public {
        require(_value > 0,"value to low");
        require(balances[msg.sender] >= _value,"balances to low");

        balances[msg.sender] -= _value;

        require(token.transfer(msg.sender, _value),"transfer error");
        
        emit withdrawLog(msg.sender, _value);


    }
    function checkbalance(address _user)public view returns(uint256) {
        return balances[_user];
    }
}