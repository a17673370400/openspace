// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./log.sol";

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/ca7a4e39de0860bbaadf95824207886e6de9fa64/contracts/utils/cryptography/ECDSA.sol#L4";

interface ITokenRecipient {
    function tokensReceived(address from, uint256 value, bytes calldata data) external;
}
contract MyERC20 is ERC20 {
    // 构造函数，设置初始 token 名称和符号，并给指定地址分配初始余额
    constructor() ERC20("aave", "AAVE") {
        _mint(msg.sender, 1000000000000000000); // 给合约创建者分配初始的 token 数量
    }
}



contract NFTMarketV1 is ITokenRecipient {
    IERC20 public token;
    uint256 public nextTokenId;
    mapping(uint256 => address) public nftOwner;

    struct Listing {
        address seller;
        uint256 price;
        bool isListed;
    }   

    mapping(uint256 => Listing) public listings;

    event Mint(address indexed owner, uint256 tokenId);
    event List(address indexed seller, uint256 tokenId, uint256 price);
    event Purchase(address indexed buyer, uint256 tokenId, uint256 price);

    constructor(address _tokenaddress) {
        token = IERC20(_tokenaddress);
    }

    function mint() external {
        uint256 tokenId = nextTokenId;
        nftOwner[tokenId] = msg.sender;
        nextTokenId++;
        emit Mint(msg.sender, tokenId);
    }

    function list(uint256 _tokenId, uint256 _price) external {
        require(nftOwner[_tokenId] == msg.sender, "not nft owner");
        require(_price > 0, "price too low");

        nftOwner[_tokenId] = address(this);
        listings[_tokenId] = Listing({
            seller: msg.sender,
            price: _price,
            isListed: true
        });

        emit List(msg.sender, _tokenId, _price);
    }

    function buyNFT(uint256 _tokenId) external {
        Listing storage lst = listings[_tokenId];
        require(lst.isListed, "nft not listed");

        uint256 price = lst.price;
        require(token.transferFrom(msg.sender, lst.seller, price), "Token transfer failed");
        nftOwner[_tokenId] = msg.sender;
        lst.isListed = false;

        emit Purchase(msg.sender, _tokenId, price);
    }

    function tokensReceived(address from, uint256 value, bytes calldata data) external override {
        require(msg.sender == address(token), "Unauthorized token");
        require(data.length == 32, "Data must contain NFT id");
        uint256 tokenId = abi.decode(data, (uint256));

        Listing storage lst = listings[tokenId];
        require(lst.isListed, "NFT not listed for sale");
        require(value == lst.price, "Token amount does not match price");

        require(token.transfer(lst.seller, value), "Transfer to seller failed");
        nftOwner[tokenId] = from;
        lst.isListed = false;

        emit Purchase(from, tokenId, value);
    }
}



contract NFTMarketV2 {
    using ECDSA for bytes32;

    IERC20 public token;
    // NFT 归属记录，mint函数将设置 NFT 的初始拥有者
    mapping(uint256 => address) public nftOwner;
    // 授权信息，用于验证 NFT 拥有者是否已授权上架
    mapping(address => bool) public approvedForAll;

    struct Listing {
        address seller;
        uint256 price;
        bool isListed;
    }

    mapping(uint256 => Listing) public listings;

    // EIP-712 相关定义
    bytes32 public constant LIST_TYPEHASH = keccak256("List(uint256 tokenId)");
    bytes32 public immutable DOMAIN_SEPARATOR;

    uint256 public nextTokenId;

    event Mint(address indexed owner, uint256 tokenId);
    event ApprovalForAll(address indexed owner, bool approved);
    event List(address indexed seller, uint256 tokenId, uint256 price);
    event Purchase(address indexed buyer, uint256 tokenId, uint256 price);
    event Debug(bytes32 digest, address signer);

    constructor(address _tokenaddress) {
        token = IERC20(_tokenaddress);

        // 初始化 EIP-712 DOMAIN_SEPARATOR
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("NFTMarketV2")), // 合约名称
                keccak256(bytes("1")),           // 版本号
                block.chainid,                   // 链 ID
                address(this)                    // 合约地址
            )
        );

        console.log(block.chainid);
        console.log(address(this));

    }

    // NFT mint 函数，设置 NFT 初始拥有者
    function mint() external {
        uint256 tokenId = nextTokenId;
        nftOwner[tokenId] = msg.sender;
        nextTokenId++;
        emit Mint(msg.sender, tokenId);
    }

    // 设置授权上架
    function setApprovalForAll(bool _approved) external {
        approvedForAll[msg.sender] = _approved;
        emit ApprovalForAll(msg.sender, _approved);
    }

    /**
     * @dev 基于 EIP-712 签名上架 NFT，使用 tokenId 签名。
     * 参数 _price 为调用时指定，不包含在签名中。
     */
    function listWithSignature(
        uint256 _tokenId,
        uint256 _price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(_price > 0, "price too low");
        require(nftOwner[_tokenId] != address(0), "invalid tokenId");
        require(approvedForAll[nftOwner[_tokenId]], "not approved");

        // 计算 EIP-712 结构哈希
        bytes32 structHash = keccak256(abi.encode(LIST_TYPEHASH, _tokenId));

        // 计算最终的 EIP-712 digest（添加 \x19\x01 和 DOMAIN_SEPARATOR）
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );

        // 恢复签名者地址
        address signer = digest.recover(v, r, s);
        console.log(signer);

        require(signer != address(0), "ECDSA: invalid signature");
        require(signer == nftOwner[_tokenId], "invalid signature");

        // 转移 NFT 并记录上架信息
        nftOwner[_tokenId] = address(this);
        listings[_tokenId] = Listing({
            seller: signer,
            price: _price,
            isListed: true
        });

        emit List(signer, _tokenId, _price);
        emit Debug(digest, signer);
    }

    // NFT 购买函数
    function buyNFT(uint256 _tokenId) external {
        Listing storage lst = listings[_tokenId];
        require(lst.isListed, "nft not listed");

        uint256 price = lst.price;
        require(token.transferFrom(msg.sender, lst.seller, price), "Token transfer failed");
        nftOwner[_tokenId] = msg.sender;
        lst.isListed = false;

        emit Purchase(msg.sender, _tokenId, price);
    }
}

pragma solidity ^0.8.0;


contract NFTMarketProxy {
    // 使用固定槽位，避免与实现合约冲突
    bytes32 private constant IMPLEMENTATION_SLOT = keccak256("eip1967.proxy.implementation");
    bytes32 private constant ADMIN_SLOT = keccak256("eip1967.proxy.admin");

    constructor(address _implementation) {
        _setImplementation(_implementation);
        _setAdmin(msg.sender);
    }

    modifier onlyAdmin() {
        require(msg.sender == _getAdmin(), "Only admin");
        _;
    }

    function upgrade(address _newImplementation) external onlyAdmin {
        _setImplementation(_newImplementation);
    }

    function initialize(address _tokenAddress) external onlyAdmin {
        (bool success, ) = _getImplementation().delegatecall(
            abi.encodeWithSignature("initialize(address)", _tokenAddress)
        );
        require(success, "Initialization failed");
    }

    function _getImplementation() private view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    function _setImplementation(address _impl) private {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, _impl)
        }
    }

    function _getAdmin() private view returns (address admin) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            admin := sload(slot)
        }
    }

    function _setAdmin(address _admin) private {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            sstore(slot, _admin)
        }
    }

    fallback() external payable {
        address impl = _getImplementation();
        require(impl != address(0), "Implementation not set");
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}