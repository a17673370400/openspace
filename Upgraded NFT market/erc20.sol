// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract MyERC20 is ERC20 {
    // 构造函数，设置初始 token 名称和符号，并给指定地址分配初始余额
    constructor() ERC20("aave", "AAVE") {
        _mint(msg.sender, 1000000000000000000); // 给合约创建者分配初始的 token 数量
    }
}