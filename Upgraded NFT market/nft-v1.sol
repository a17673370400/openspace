// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

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