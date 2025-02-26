// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";



contract MyPermitToken is ERC20, ERC20Permit {
    constructor() ERC20("MyPermitToken", "MPT") ERC20Permit("MyPermitToken") {
        // 初始发行 1,000,000 代币，考虑代币小数位数（默认为 18）
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }
}

contract DeployMyPermitToken is Script {
    function run() external {
        // 开始广播，之后的所有操作都会发送到指定网络
        vm.startBroadcast();
        // 部署 MyPermitToken 合约
        new MyPermitToken();
        vm.stopBroadcast();
    }
}

