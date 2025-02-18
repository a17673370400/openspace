// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";



contract BankTest is Test {
    Bank bank;
    address user = address(0); //设置一个测试用户
    uint depositAmount = 1 ether;
    event Deposit(address indexed user, uint amount);

    function setUp() public{
        bank = new Bank();
        vm.deal(user,10 ether); //初始化测试用户的一个余额 10个以太坊
    }

    function test_deposit() public{
        // 断言存款前的余额
        uint balancebf = bank.balanceOf(user);
        assertEq(balancebf, 0);
        // 使用作弊码 设置发起人为测试用户
        vm.prank(user);


        bank.depositETH{value:depositAmount}();
        emit Deposit(user, depositAmount);
        uint balanceafter = bank.balanceOf(user);

        assertEq(balanceafter,depositAmount);


    }


}