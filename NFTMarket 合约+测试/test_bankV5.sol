// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarket} from "../src/tokenBankV5.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DummyERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }
}


contract CounterTest is Test {
    NFTMarket public nftmaker;
    address user = address(1); //设置一个测试用户
    address user1 = address(2); //设置一个测试用户
    DummyERC20 public token;
    event List(address indexed seller,uint256 tokenId,uint256 price);


    function setUp() public {
        nftmaker = new NFTMarket();
        token = new DummyERC20("test", "TEST");
        token.transfer(user1, 1000 * 10 ** token.decimals());

    }

    function test_list() public {
        vm.prank(user);
        nftmaker.mint();
        address erc20Address = address(token);

        vm.expectRevert("not nftowner");
        nftmaker.list(0,100,address(erc20Address));

        vm.prank(user);
        nftmaker.mint();

        vm.expectEmit(true, false, false, true);
        emit List(user, 1, 100);

        // 成功调用 list 函数，上架 tokenId 1
        vm.prank(user);
        nftmaker.list(1, 100, erc20Address);



    }

    function test_buy() public {
        vm.expectRevert("nft no list");
        nftmaker.buyNFT(0);

        vm.prank(user);
        nftmaker.mint();

        vm.prank(user);
        nftmaker.list(0, 100, address(token));


        vm.prank(user1);
        token.approve(address(nftmaker), 100000);

        vm.prank(user1);
        nftmaker.buyNFT(0);
        assertEq(nftmaker.nftOwner(0), user1);

        vm.prank(user1);
        nftmaker.mint();

        vm.prank(user1);
        nftmaker.list(1, 100, address(token));

        vm.prank(user1);
        vm.expectRevert("not nftowner buy");
        nftmaker.buyNFT(1);
    }


function testFuzz_list(uint256 _price, address buyer) public {
    // 假设 Token 有18个小数位，将价格限定在0.01~10000 Token之间
    // 避免 buyer 为零地址，且不能与上架者 user 相同
    // 由 user 铸造 NFT（tokenId 默认为0）
    // 由 user 上架 NFT，价格为随机生成的 price，支付代币为 token
    // 为 buyer 转入足够数量的 token，确保 buyer 能够支付（这里转入 price * 2）
    // buyer 授权市场合约使用 token\
    // buyer 购买 NFT\
    // 验证 NFT 的新所有者为 buyer\

    uint256 price = bound(_price, 0.1 ether, 10000 ether);
    vm.assume(buyer != address(0) && buyer != user);

    vm.prank(user);
    nftmaker.mint();

    vm.prank(user);
    nftmaker.list(0,price,address(token));

    token.transfer(buyer,price);

    vm.prank(buyer);
    token.approve(address(nftmaker),price);

    vm.prank(buyer);
    nftmaker.buyNFT(0);

    assertEq(nftmaker.nftOwner(0) , buyer);
}

}

