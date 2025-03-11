// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../src/ido.sol";



contract IdoTest is Test {
    Myerc20 public myerc20;
    ido public idoContract;

    address public owner = address(0x11);
    address public user1 = address(0x123);
    address public user2 = address(0x456);

    uint256 public constant PRICE = 1e18; // 1 ETH = 1 token (wei单位)
    uint256 public constant TOTAL_RAISE = 10e18; // 目标筹集 10 ETH (wei单位)
    uint256 public constant DEADLINE = 1 days; // 预售持续 1 天
    uint256 public constant MINT_AMOUNT = 100e18; // 给 ido 合约铸造 100 tokens (wei单位)

    function setUp() public {
        vm.startPrank(owner);

        myerc20 = new Myerc20();
        idoContract = new ido(address(myerc20), PRICE, TOTAL_RAISE, DEADLINE);
        assertEq(address(idoContract.token()), address(myerc20));

        myerc20.mint(address(idoContract), MINT_AMOUNT);
        vm.stopPrank();
    }

    // 测试预售功能
    function testPreSale() public {
        vm.deal(user1, 15e18);
        vm.prank(user1);
        vm.expectRevert("Exceeding the maximum");
        idoContract.preSale{value: 11e18}();

        assertEq(idoContract.Total(), 0, "Total should not increase on failed preSale");

        vm.prank(user1);
        idoContract.preSale{value: 2e18}();

        assertEq(idoContract.Total(), 2e18, "Total should be 2 ETH");
        assertEq(idoContract.UserTotal(user1), 2, "UserTotal should be 2 tokens"); // 改为 2
        assertEq(address(idoContract).balance, 2e18, "Contract balance should be 2 ETH");
    }

    // 测试退款功能
    function testPresaleRefund() public {
        vm.deal(user1, 5e18);
        vm.prank(user1);
        idoContract.preSale{value: 2e18}();

        vm.warp(block.timestamp + DEADLINE + 1);
        assertEq(idoContract.Total(), 2e18);

        uint256 user1BalanceBefore = user1.balance;
        vm.prank(user1);
        idoContract.Presalerefund();

        assertEq(idoContract.UserTotal(user1), 0);
        assertEq(user1.balance, user1BalanceBefore + 2e18);
    }

    // 测试代币领取功能
    function testUserTokenClaim() public {
        vm.deal(user1, 5e18);
        vm.prank(user1);
        idoContract.preSale{value: 5e18}();

        vm.deal(user2, 5e18);
        vm.prank(user2);
        idoContract.preSale{value: 5e18}();

        vm.warp(block.timestamp + DEADLINE + 1);
        assertEq(idoContract.Total(), 10e18);

        vm.prank(user1);
        idoContract.UserTokenClaim();

        assertEq(myerc20.balanceOf(user1), 5, "user1 should receive 5 tokens"); // 改为 5
        assertEq(idoContract.UserTotal(user1), 0);
    }

    // 测试开发者提取资金
    function testDevClaim() public {
        vm.deal(user1, 5e18);
        vm.prank(user1);
        idoContract.preSale{value: 5e18}();

        vm.deal(user2, 5e18);
        vm.prank(user2);
        idoContract.preSale{value: 5e18}();

        vm.warp(block.timestamp + DEADLINE + 1);
        assertEq(idoContract.Total(), 10e18);

        vm.prank(owner);
        idoContract.devClaim();
        assertEq(owner.balance, 10e18, "owner should receive 10 ETH");
    }

}