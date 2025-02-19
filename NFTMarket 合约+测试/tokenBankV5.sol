// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

// 定义接收方接口，要求接收方实现 tokensReceived 回调函数
interface ITokenRecipient {
    function tokensReceived(address from, uint256 value, bytes calldata data) external;
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

    constructor() {
        // 初始化：将所有代币分配给部署者
        balances[msg.sender] = totalSupply;  
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);  
        return true;   
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowances[_from][msg.sender] >= _value, "ERC20: transfer amount exceeds allowance");
        require(balances[_from] >= _value, "ERC20: transfer amount exceeds balance");

        allowances[_from][msg.sender] -= _value;
        balances[_from] -= _value;
        balances[_to] += _value;        
        emit Transfer(_from, _to, _value); 
        return true; 
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {     
        return allowances[_owner][_spender];
    }

    // 新增带回调功能的转账函数
    function transferWithCallback(address _to, uint256 _value, bytes calldata _data) public returns (bool success) {
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");

        // 扣除发送方余额，并增加接收方余额
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);

        // 如果 _to 是合约地址，则调用其 tokensReceived() 方法
        if (_to.code.length > 0) {
            ITokenRecipient(_to).tokensReceived(msg.sender, _value, _data);
        }

        return true;
    }
}


contract TokenBank {
    IERC20 public token;
    mapping(address => uint256) public balances;
    
    event depositLog(address indexed _address, uint256 value);
    event withdrawLog(address indexed _address, uint256 value);
    event depositLog1(address indexed _address, uint256 value,bytes data);

    constructor(address _tokenaddress){
        token = IERC20(_tokenaddress);
    }

    function deposit(uint256 _value) public {
        require(_value > 0, "value too low");
        require(token.allowance(msg.sender, address(this)) >= _value, "approve tokenbank first");
        require(token.balanceOf(msg.sender) >= _value, "Insufficient token balance");

        require(token.transferFrom(msg.sender, address(this), _value), "transfer failed");
        balances[msg.sender] += _value;
        emit depositLog(msg.sender, _value);
    }

    function withdraw(uint256 _value) public {
        require(_value > 0, "value too low");
        require(balances[msg.sender] >= _value, "balance too low");

        balances[msg.sender] -= _value;
        require(token.transfer(msg.sender, _value), "transfer error");
        emit withdrawLog(msg.sender, _value);
    }

    function checkbalance(address _user) public view returns(uint256) {
        return balances[_user];
    }
}

// TokenBankV2 继承自 TokenBank，并实现 tokensReceived 回调函数
contract TokenBankV2 is TokenBank {
    constructor(address _tokenaddress) TokenBank(_tokenaddress) {}

    // 实现 tokensReceived，用于处理通过 transferWithCallback 直接转入的存款
    function tokensReceived(address from, uint256 value, bytes calldata data) external {
        // 确保调用方是我们预期的 ERC20 Token 合约
        require(msg.sender == address(token), "Unauthorized sender");
        
        // 更新用户存款余额
        balances[from] += value;
        emit depositLog1(from, value,data);

    }
}

contract NFTMarket is ITokenRecipient{

    // nft编号
    uint256 public nextTokenId;

    // 记录nft的所有人 如果上架了就要吧他转换给合约地址来托管
    mapping(uint256 => address) public nftOwner;


    struct Listing {
        address seller;
        uint256 price;
        address paymentToken;
        bool isListed;
        // 卖家 价格 指定可以接受的token  是否上架
    }

    mapping(uint256 => Listing) public listings;


    event Mint(address indexed owner,uint256 tokenId);
    event List(address indexed seller,uint256 tokenId,uint256 price);
    event Purchase(address indexed buyer,uint256 tokenId,uint256 price,address paymentToken);

    function mint() external{
        uint256 tokenId = nextTokenId;
        nftOwner[tokenId] = msg.sender;
        nextTokenId++;
        emit Mint(msg.sender,tokenId);
    }

    function list(uint256 _tokenId,uint256 _price,address paymentToken) external{
        require(nftOwner[_tokenId] == msg.sender,"not nftowner");
        require(_price > 0,"price to low");
        require(paymentToken != address(0),"paymentToken is zero address");
        // 上架后 NFT合约管理
        nftOwner[_tokenId] = address(this);
        listings[_tokenId] = Listing({
            seller:msg.sender,
            price:_price,
            paymentToken:paymentToken,
            isListed:true
        });

        emit List(msg.sender, _tokenId, _price);
    }

    function buyNFT(uint256 _tokenId) external{
        Listing storage lst = listings[_tokenId];
        require(lst.isListed,"nft no list");
        require(msg.sender != lst.seller,"not nftowner buy");

        // 调用支付合约
        IERC20 payToken  = IERC20(lst.paymentToken);
        uint256 price = lst.price;
        require(payToken.transferFrom(msg.sender, lst.seller, lst.price), "Payment transfer failed");
        nftOwner[_tokenId] = msg.sender;
        lst.isListed = false;

        emit Purchase(msg.sender, _tokenId, price, lst.paymentToken);

        // 转移nft  所有者转换 上架状态为假;
    }

    function tokensReceived(address from, uint256 value, bytes calldata data) external override {
        // 从 data 中解析出 NFT id，要求 data 长度为 32 字节
        require(data.length == 32, "Data must contain NFT id");
        uint256 tokenId = abi.decode(data, (uint256));
            // 根据 tokenId 获取对应的上架信息
        Listing storage lst = listings[tokenId];

        // 确保调用者是预期的支付代币合约
        require(msg.sender == lst.paymentToken, "Unauthorized token");

        // 检查 NFT 是否上架，以及支付金额是否匹配
        require(lst.isListed, "NFT not listed for sale");
        require(value == lst.price, "Token amount does not match price");

        // 将支付的代币转给卖家
        require(IERC20(lst.paymentToken).transfer(lst.seller, value), "Transfer to seller failed");

        // NFT 转移给买家，取消上架状态
        nftOwner[tokenId] = from;
        lst.isListed = false;

        emit Purchase(from, tokenId, value, lst.paymentToken);

    }

}