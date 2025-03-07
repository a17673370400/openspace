const { ethers } = require("ethers");

console.log("ethers version:", ethers.version);

// 使用你的私钥
// 503f38a9c967ed597e47fe25643985f032b072db8075426a92110f82df48dfcb   remix第一个地址


const privateKey = "";
const wallet = new ethers.Wallet(privateKey);

const domain = {
    name: "NFTMarketV2",
    version: "1",
    chainId: 11155111, // Sepolia 网络的链 ID
    // chainId: 11155111, // Sepolia 网络的链 ID
    verifyingContract: "0x7f9D53de1aAabD7AF730A1a7c5fa86513c49b54F" // 替换为实际部署的 NFTMarketV2 合约地址
};



const types = {
    List: [
        { name: "tokenId", type: "uint256" }
    ]
};

// 要签名的数据
const value = {
    tokenId: 1 // 示例 tokenId，可根据需要调整
};

async function signHash() {
    try {
        // 使用 signTypedData 生成 EIP-712 签名
        const signature = await wallet.signTypedData(domain, types, value);

        // 拆分签名
        const sig = ethers.Signature.from(signature);
        const { v, r, s } = sig;

        // 计算 digest（用于调试，与链上对比）
        const LIST_TYPEHASH = ethers.keccak256(ethers.toUtf8Bytes("List(uint256 tokenId)"));
        const structHash = ethers.keccak256(
            ethers.solidityPacked(["bytes32", "uint256"], [LIST_TYPEHASH, value.tokenId])
        );
        const domainSeparator = ethers.keccak256(
            ethers.solidityPacked(
                ["bytes32", "bytes32", "bytes32", "uint256", "address"],
                [
                    ethers.keccak256(ethers.toUtf8Bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")),
                    ethers.keccak256(ethers.toUtf8Bytes(domain.name)),
                    ethers.keccak256(ethers.toUtf8Bytes(domain.version)),
                    domain.chainId,
                    domain.verifyingContract
                ]
            )
        );
        const digest = ethers.keccak256(
            ethers.solidityPacked(["string", "bytes32", "bytes32"], ["\x19\x01", "0x0671b03298316acb164976069d2cf6a915c405463480c3bc8766a29f2b38ede0", "0x6386136263cd0eb7ee9060830578f9335b06024856ca23c5729e6b235a2a0a49"])
        );

        // 输出结果
        console.log("Digest:", digest);
        console.log("Signature:", { v, r, s });
        console.log("Signer address:", wallet.address);
    } catch (error) {
        console.error("Error signing message:", error);
    }
}

// 执行签名
signHash();