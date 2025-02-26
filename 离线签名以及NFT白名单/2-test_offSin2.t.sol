    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;

    import "forge-std/Test.sol";
    import "../script/offSign2.sol";  // 确保 MockERC20 被正确导入

contract test_offSin2 is Test {
    MockERC20 token;
    TokenBank bank;

    uint256 privateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; // 代表用户的私钥（用于测试）
    address user;
    uint256 depositAmount = 1000 * 10 ** 18;
    uint256 deadline;

    function setUp() public {
        token = new MockERC20();
        bank = new TokenBank(address(token));

        user = vm.addr(privateKey);
        deadline = block.timestamp + 1000;

        // 给用户初始代币
        token.transfer(user, 3000 * 10 ** 18);
    }

    /// **测试 1: 正确的 `permitDeposit`**
    function testPermitDeposit() public {
        uint256 nonce = token.nonces(user);

        // 构造 permit 的哈希
        bytes32 structHash = keccak256(
            abi.encode(
                token.PERMIT_TYPEHASH(),
                user,
                address(bank),
                depositAmount,
                nonce,
                deadline
            )
        );

        // 生成 EIP-712 签名
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        // 调用 permitDeposit
        vm.prank(user);
        bank.permitDeposit(user, depositAmount, deadline, v, r, s);

        // 验证存款是否成功
        uint256 balanceInBank = bank.checkbalance(user);
        assertEq(balanceInBank, depositAmount, "Deposit amount incorrect");

        uint256 ercBanlance = token.balanceOf(user);
        assertEq(3000 * 10 ** 18 - balanceInBank, 2000 * 10 ** 18, "remain2000 * 10 ** 18");




    }

    /// **测试 2: 修改 `value` 让签名无效**
    function testPermitDepositWithWrongValue() public {
        uint256 nonce = token.nonces(user);
        uint256 wrongAmount = depositAmount + 10 * 10 ** 18; // 人为修改 value

        // 构造错误的 `permit` 哈希（错误的 value）
        bytes32 structHash = keccak256(
            abi.encode(
                token.PERMIT_TYPEHASH(),
                user,
                address(bank),
                wrongAmount, // **错误的金额**
                nonce,
                deadline
            )
        );

        // 生成错误的 EIP-712 签名
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        // 预期 revert，因为 `value` 与签名的不匹配
        vm.prank(user);
        vm.expectRevert("Permit: invalid signature");
        bank.permitDeposit(user, depositAmount, deadline, v, r, s);
    }

    ///  **测试 3: 过期的 `permit` 签名**
    function testPermitDepositWithExpiredSignature() public {
        uint256 nonce = token.nonces(user);
        uint256 expiredDeadline = block.timestamp - 1; // 过期时间

        // 构造 `permit` 哈希（过期的时间戳）
        bytes32 structHash = keccak256(
            abi.encode(
                token.PERMIT_TYPEHASH(),
                user,
                address(bank),
                depositAmount,
                nonce,
                expiredDeadline
            )
        );

        // 生成过期的 EIP-712 签名
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        // 预期 revert，因为 `deadline` 已过期
        vm.prank(user);
        vm.expectRevert("Permit: expired deadline");
        bank.permitDeposit(user, depositAmount, expiredDeadline, v, r, s);
    }
}
