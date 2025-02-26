    // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
//
// ERC20 标准接口
//
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

//
// EIP-2612 permit 接口
//
interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
}

//
// ERC20 基础实现（BaseERC20）
//
contract BaseERC20 {
    string public name = "BaseERC20"; 
    string public symbol = "BERC20"; 
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * 10 ** 18; 

    mapping(address => uint256) public balances; 
    mapping(address => mapping(address => uint256)) public allowances; 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balances[msg.sender] = totalSupply;  
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] >= _value, "ERC20: insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);  
        return true;   
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(allowances[_from][msg.sender] >= _value, "ERC20: allowance exceeded");
        require(balances[_from] >= _value, "ERC20: insufficient balance");

        allowances[_from][msg.sender] -= _value;
        balances[_from] -= _value;
        balances[_to] += _value;        
        emit Transfer(_from, _to, _value); 
        return true; 
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {     
        return allowances[_owner][_spender];
    }
}

//
// 支持 EIP-2612 permit 的 MockERC20
//
contract MockERC20 is BaseERC20, IERC20Permit {
    mapping(address => uint256) public nonces;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)), 
                keccak256(bytes("1")),  
                chainId,
                address(this)
            )
        );
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(block.timestamp <= deadline, "Permit: expired deadline");

        uint256 currentNonce = nonces[owner];
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentNonce, deadline))
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "Permit: invalid signature");

        nonces[owner] = currentNonce + 1;
        allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}

//
// 代币银行（TokenBank），支持 permitDeposit
//
contract TokenBank {
    IERC20 public token;
    mapping(address => uint256) public balances;

    event depositLog(address indexed _address, uint256 value);
    event withdrawLog(address indexed _address, uint256 value);

    constructor(address _tokenaddress) {
        token = IERC20(_tokenaddress);
    }

    /// @notice 普通存款：用户需提前 approve 授权
    function deposit(uint256 _value) public {
        require(_value > 0, "Value too low");
        require(token.allowance(msg.sender, address(this)) >= _value, "Approve TokenBank first");
        require(token.balanceOf(msg.sender) >= _value, "Insufficient token balance");

        require(token.transferFrom(msg.sender, address(this), _value), "Transfer failed");
        balances[msg.sender] += _value;
        emit depositLog(msg.sender, _value);
    }

    /// @notice permitDeposit：离线签名存款，用户无需预先 approve  
    function permitDeposit(
        address owner,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(value > 0, "Value too low");
        require(msg.sender == owner, "Caller must be owner");

        // 调用代币的 permit 方法，授权 TokenBank 转走用户代币
        IERC20Permit(address(token)).permit(owner, address(this), value, deadline, v, r, s);

        // 调用 transferFrom 转账
        require(token.transferFrom(owner, address(this), value), "Transfer failed");
        balances[owner] += value;
        emit depositLog(owner, value);
    }

    /// @notice 提现用户存款
    function withdraw(uint256 _value) public {
        require(_value > 0, "Value too low");
        require(balances[msg.sender] >= _value, "Insufficient balance");

        balances[msg.sender] -= _value;
        require(token.transfer(msg.sender, _value), "Transfer failed");
        emit withdrawLog(msg.sender, _value);
    }

    /// @notice 查询用户存款
    function checkbalance(address _user) public view returns (uint256) {
        return balances[_user];
    }
}
