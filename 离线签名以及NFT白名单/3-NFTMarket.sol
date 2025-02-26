// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface ITokenRecipient {
    function tokensReceived(address from, uint256 value, bytes calldata data) external;
}

contract MockERC20 is IERC20 {
    string public name = "MockERC20";
    string public symbol = "MERC";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * 10 ** 18;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(allowances[sender][msg.sender] >= amount, "ERC20: allowance too low");
        require(balances[sender] >= amount, "ERC20: balance too low");

        allowances[sender][msg.sender] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount;
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(balances[msg.sender] >= amount, "ERC20: balance too low");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        return true;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowances[msg.sender][spender] = amount;
        return true;
    }
}

contract NFTMarket is ITokenRecipient, EIP712 {
    using ECDSA for bytes32;

    uint256 public nextTokenId;
    mapping(uint256 => address) public nftOwner;

    struct Listing {
        address seller;
        uint256 price;
        address paymentToken;
        bool isListed;
    }

    mapping(uint256 => Listing) public listings;
    mapping(address => uint256) public whitelistNonces;

    address public immutable projectOwner;

    event Mint(address indexed owner, uint256 tokenId);
    event List(address indexed seller, uint256 tokenId, uint256 price);
    event Purchase(address indexed buyer, uint256 tokenId, uint256 price, address paymentToken);

bytes32 public constant PERMIT_TYPEHASH =
    keccak256("PermitBuy(address buyer,uint256 tokenId,uint256 price,uint256 nonce,uint256 deadline)");

    constructor(address _projectOwner) EIP712("NFTMarket", "1") {
        projectOwner = _projectOwner;
    }

    function mint() external {
        uint256 tokenId = nextTokenId;
        nftOwner[tokenId] = msg.sender;
        nextTokenId++;
        emit Mint(msg.sender, tokenId);
    }
function hashTypedDataV4(bytes32 structHash) external view returns (bytes32) {
    return _hashTypedDataV4(structHash);
}

    function list(uint256 _tokenId, uint256 _price, address paymentToken) external {
        require(nftOwner[_tokenId] == msg.sender, "Not NFT owner");
        require(_price > 0, "Price too low");
        require(paymentToken != address(0), "Invalid payment token");

        nftOwner[_tokenId] = address(this);
        listings[_tokenId] = Listing({
            seller: msg.sender,
            price: _price,
            paymentToken: paymentToken,
            isListed: true
        });

        emit List(msg.sender, _tokenId, _price);
    }

    function buyNFT(uint256 _tokenId) public {
        Listing storage lst = listings[_tokenId];
        require(lst.isListed, "NFT not listed");
        require(msg.sender != lst.seller, "Seller cannot buy");

        IERC20 payToken = IERC20(lst.paymentToken);
        require(payToken.transferFrom(msg.sender, lst.seller, lst.price), "Payment transfer failed");

        nftOwner[_tokenId] = msg.sender;
        lst.isListed = false;

        emit Purchase(msg.sender, _tokenId, lst.price, lst.paymentToken);
    }

    function permitBuy(
        uint256 _tokenId,
        uint256 _price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= deadline, "Permit expired");

        uint256 nonce = whitelistNonces[msg.sender];
        whitelistNonces[msg.sender]++;

        bytes32 structHash = keccak256(
            abi.encode(PERMIT_TYPEHASH, msg.sender, _tokenId, _price, nonce, deadline)
        );

        bytes32 digest = _hashTypedDataV4(structHash);
        address recoveredSigner = digest.recover(v, r, s);

        require(recoveredSigner == projectOwner, "Invalid signature");

        buyNFT(_tokenId);
    }

    function tokensReceived(address from, uint256 value, bytes calldata data) external override {
        require(data.length == 32, "Invalid data length");
        uint256 tokenId = abi.decode(data, (uint256));

        Listing storage lst = listings[tokenId];
        require(msg.sender == lst.paymentToken, "Unauthorized token");
        require(lst.isListed, "NFT not listed");
        require(value == lst.price, "Price mismatch");

        require(IERC20(lst.paymentToken).transfer(lst.seller, value), "Transfer failed");

        nftOwner[tokenId] = from;
        lst.isListed = false;

        emit Purchase(from, tokenId, value, lst.paymentToken);
    }
}
