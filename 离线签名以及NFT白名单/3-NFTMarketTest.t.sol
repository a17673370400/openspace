// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/NFTMarket.sol";

contract NFTMarketTest is Test {
    MockERC20 token;
    NFTMarket market;
    address projectOwner;
    address user;
    address buyer;
    uint256 price = 100 * 10 ** 18;
    uint256 deadline;

    function setUp() public {
        projectOwner = vm.addr(1);
        user = vm.addr(2);  // 作为 NFT 卖家
        buyer = vm.addr(3); // 作为 NFT 购买者
        market = new NFTMarket(projectOwner);
        token = new MockERC20();

        // 给买家一些 Token 进行购买

        token.transfer(buyer, price);
    }

    function testPermitBuy() public {
        uint256 tokenId = market.nextTokenId();

        // 用户 mint NFT
        vm.prank(user);
        market.mint();

        // 用户上架 NFT
        vm.prank(user);
        market.list(tokenId, price, address(token));

        // 生成白名单签名（给 buyer 允许购买）
        uint256 nonce = market.whitelistNonces(buyer);
        deadline = block.timestamp + 1000;

        bytes32 structHash = keccak256(
            abi.encode(market.PERMIT_TYPEHASH(), buyer, tokenId, price, nonce, deadline)
        );

        // 生成签名
        bytes32 digest = market.hashTypedDataV4(structHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest); // 用 projectOwner 生成签名

        // 买家授权 NFTMarket 支出 Token
        vm.prank(buyer);
        token.approve(address(market), price);

        // 买家通过 permitBuy 购买 NFT
        vm.prank(buyer);
        market.permitBuy(tokenId, price, deadline, v, r, s);

        // **测试 NFT 归属**
        assertEq(market.nftOwner(tokenId), buyer, "NFT should be owned by buyer");

        // **测试 Token 支付**
        assertEq(token.balanceOf(buyer), 0, "Buyer should have paid");
        assertEq(token.balanceOf(user), price, "Seller should have received payment");
    }
}
