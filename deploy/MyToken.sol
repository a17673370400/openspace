// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract MyToken is ERC20 { 
    
    constructor(string memory  name_, string memory  symbol_) ERC20(name_, symbol_) {
        _mint(msg.sender, 1e10*1e18);
    } 
}

Deployer: 0xA2994BaBAd41563100357Ff8caB1442EFED3678C
Deployed to: 0xFDfA91105B25DCf747d949D4ee4C87dfc87ED5e9
Transaction hash: 0xb876f62a40457ec5e174a7107c70c4e134be21e197ab9520b46b3b08bbaafbfd
