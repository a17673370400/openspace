// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract NFTMarketProxy {
    // 使用固定槽位，避免与实现合约冲突
    bytes32 private constant IMPLEMENTATION_SLOT = keccak256("eip1967.proxy.implementation");
    bytes32 private constant ADMIN_SLOT = keccak256("eip1967.proxy.admin");

    constructor(address _implementation) {
        _setImplementation(_implementation);
        _setAdmin(msg.sender);
    }

    modifier onlyAdmin() {
        require(msg.sender == _getAdmin(), "Only admin");
        _;
    }

    function upgrade(address _newImplementation) external onlyAdmin {
        _setImplementation(_newImplementation);
    }

    function initialize(address _tokenAddress) external onlyAdmin {
        (bool success, ) = _getImplementation().delegatecall(
            abi.encodeWithSignature("initialize(address)", _tokenAddress)
        );
        require(success, "Initialization failed");
    }

    function _getImplementation() private view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    function _setImplementation(address _impl) private {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, _impl)
        }
    }

    function _getAdmin() private view returns (address admin) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            admin := sload(slot)
        }
    }

    function _setAdmin(address _admin) private {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            sstore(slot, _admin)
        }
    }

    fallback() external payable {
        address impl = _getImplementation();
        require(impl != address(0), "Implementation not set");
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}