    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;
    import "./log.sol";
    import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/ca7a4e39de0860bbaadf95824207886e6de9fa64/contracts/utils/cryptography/MerkleProof.sol#L4";
    import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/ca7a4e39de0860bbaadf95824207886e6de9fa64/contracts/utils/cryptography/ECDSA.sol#L4";

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


        using ECDSA for bytes32;

        // EIP-712 相关定义
        bytes32 public constant LIST_TYPEHASH = keccak256("approve(uint256 value)");
        bytes32 public immutable DOMAIN_SEPARATOR;

        mapping (address => uint256) balances; 
        mapping (address => mapping (address => uint256)) allowances; 

        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);

        constructor() {
            // 初始化：将所有代币分配给部署者
            balances[msg.sender] = totalSupply;

            DOMAIN_SEPARATOR = keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes("BaseERC20")), // 合约名称
                    keccak256(bytes("1")),           // 版本号
                    block.chainid,                   // 链 ID
                    address(this)                    // 合约地址
                )
            );
            console.log(block.chainid);
            console.log(address(this));
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

        function permitPrePay(
            address owner,
            address _spender,
            uint256 _value,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) external returns (bool){
            bytes32 structHash = keccak256(abi.encode(LIST_TYPEHASH, _value));

            bytes32 digest = keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
            );

            address signer = digest.recover(v, r, s);
            console.log(signer);
            require(signer == owner, "invalid signature");

            allowances[owner][_spender] = _value;
            emit Approval(msg.sender, _spender, _value); 
            return true; 

        }
    }

    contract AirdopMerkleNFTMarket  is ITokenRecipient{
        // 使用什么token作为 支付；
        bytes32 public mkroot;
        IERC20 public token;

        // nft编号
        uint256 public nextTokenId;

        // 记录nft的所有人 如果上架了就要吧他转换给合约地址来托管
        mapping(uint256 => address) public nftOwner;


        struct Listing {
            address seller;
            uint256 price;
            bool isListed;
            // 卖家 价格 是否上架
        }

        mapping(uint256 => Listing) public listings;


        event Mint(address indexed owner,uint256 tokenId);
        event List(address indexed seller,uint256 tokenId,uint256 price);
        event Purchase(address indexed buyer,uint256 tokenId,uint256 price);

        // 传入支付token
        constructor(address _tokenaddress,bytes32 _mkroot){
            token = IERC20(_tokenaddress);
            mkroot = _mkroot;
        }



        function mint() external{
            uint256 tokenId = nextTokenId;
            nftOwner[tokenId] = msg.sender;
            nextTokenId++;
            emit Mint(msg.sender,tokenId);
        }

        function list(uint256 _tokenId,uint256 _price) external{
            require(nftOwner[_tokenId] == msg.sender,"not nftowner");
            require(_price > 0,"price to low");

            // 上架后 NFT合约管理
            nftOwner[_tokenId] = address(this);
            listings[_tokenId] = Listing({
                seller:msg.sender,
                price:_price,
                isListed:true
            });

            emit List(msg.sender, _tokenId, _price);
        }

        function buyNFT(uint256 _tokenId) external{
            Listing storage lst = listings[_tokenId];
            require(lst.isListed,"nft no list");

            uint256 price = lst.price;

            require(token.transferFrom(msg.sender, lst.seller, price), "Token transfer failed");
            nftOwner[_tokenId] = msg.sender;
            lst.isListed = false;

            emit Purchase(msg.sender, _tokenId, price);

            // 转移nft  所有者转换 上架状态为假;
        }

        function claimNFT(uint256 _tokenId,bytes32 []  memory proof,address account) external{
            Listing storage lst = listings[_tokenId];
            require(lst.isListed,"nft no list");

            bytes32 leaf = keccak256(abi.encode(account));
            require(MerkleProof.verify(proof,mkroot,leaf),"invalid proof");

            uint256 price = lst.price / 2;

            require(token.transferFrom(account, lst.seller, price), "Token transfer failed");
            nftOwner[_tokenId] = account;
            lst.isListed = false;

            emit Purchase(msg.sender, _tokenId, price);

            // 转移nft  所有者转换 上架状态为假;
        }


        function tokensReceived(address from, uint256 value, bytes calldata data) external override {
            // 确保调用者为我们预期的 token 合约
            require(msg.sender == address(token), "Unauthorized token");

            // data 中解析出 NFT id，要求 data 长度为 32 字节
            require(data.length == 32, "Data must contain NFT id");
            uint256 tokenId = abi.decode(data, (uint256));

            Listing storage lst = listings[tokenId];
            require(lst.isListed, "NFT not listed for sale");
            require(value == lst.price, "Token amount does not match price");

            // 将 token 转给卖家
            require(token.transfer(lst.seller, value), "Transfer to seller failed");

            // NFT 转移给买家
            nftOwner[tokenId] = from;
            // 取消上架状态
            lst.isListed = false;

            emit Purchase(from, tokenId, value);
        }

    }


    contract Multicall {
        // Structure to hold the details of each call
        struct Call {
            address target; // Target contract address
            bytes callData; // Encoded function call
        }

        // Event to indicate the result of a call
        event CallExecuted(
            address indexed target,
            bool success,
            bytes data
        );

        // The multicall function accepts an array of `Call` objects and executes them.
        function multiCall(Call[] calldata calls) external {
            for (uint i = 0; i < calls.length; i++) {
                // Execute call to target contract
                (bool success, bytes memory data) = calls[i].target.call(calls[i].callData);

                // Emit an event with the result of the call
                emit CallExecuted(calls[i].target, success, data);

                // Revert if any call fails, optional behavior
                require(success, "Call failed");
            }
        }
    }

