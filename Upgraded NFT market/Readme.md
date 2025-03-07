# nft离线签名 部署合约



---

## 1. 流程


### 1.1 初始化erc20Token地址
- ```solodity
    pragma solidity ^0.8.0;
    import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

    contract MyERC20 is ERC20 {
        // 构造函数，设置初始 token 名称和符号，并给指定地址分配初始余额
        constructor() ERC20("aave", "AAVE") {
            _mint(msg.sender, 1000000000000000000); // 给合约创建者分配初始的 token 数量
        }
    }
    哈希地址：
    https://sepolia.etherscan.io/tx/0xf7ea1c3d0937a858b887f62d7a25ad0bf7d35feed09e0e0b6fd2aae437d5738c    
    部署合约地址：0xdc5e4965b8b852e94638a6cce5cec351322ce884

-

### 1.2 部署nftV1-V2合同地址 指向erc20token 
- ```solodity
    nftv1-哈希地址：
    https://sepolia.etherscan.io/tx/0x9581bbb9a436c3400df218e65ab828803b7875027f477e17c9c8cdaf7a4eba82
    部署合约地址：0x8A83bb72CEf9B37142385750f5ED2d0424084Ff9

    nftv2-哈希地址：
    https://sepolia.etherscan.io/tx/0xbc4bc94e55488cca2063d8251ff7a5b26c7cb5bd261564691c04027adf8f4917
    部署合约地址：0x7f9D53de1aAabD7AF730A1a7c5fa86513c49b54F
-

###  1.3 部署代理合同地址 指向nft-v1
- ```solodity
    代理合同地址 指向nftv1-哈希地址：
    https://sepolia.etherscan.io/tx/0xa7242450755205e2aa5c0da846454c92e6e14b8cbd311f06647fa3633a779793
    部署合约地址：0xbc1a679ad400c8b1e8c57b8461c5bb500a9f5d48

-

###  1.3 升级合同合约 指向nft-v2
- ```solodity
    级合同合约 指向nft-v2：
    https://sepolia.etherscan.io/tx/0xdf4362f577139d0e1c1d83467a028f2be0e03147ab40d5371368214139f7ee2e

-

###  1.4 mint nft以及错误的上架 和 错误的签名 

-   通过call 选择器方法 0x1249c58b mint 5个 nft

-   通过call 选择器方法 listWithSignature  哈希
    https://sepolia.etherscan.io/tx/0xa33ab2744d2a7e6c7f95d65ff363318b94b079138c87e6b31cbc26c796fc0e61
    返回Fail with error 'not approved'


-   通过call 选择器方法 setApprovalForAll true 哈希
    https://sepolia.etherscan.io/tx/0xa86e9ff780fa15c6a88fff0cac614f92a20427e9dd7f260950f7145c95c7d11c


-   通过无效的离线签名参数 哈希：
    https://sepolia.etherscan.io/tx/0x8e81326bbf70695015e0505d4587833b21c5febc74624dc261cf4b1be1888988
    返回Fail with error 'invalid signature'

-   通过正确的离线签名参数 上架nft 哈希
    https://sepolia.etherscan.io/tx/0x7efa1b6cf0207d2920fd57b114749b8d18c1e9ee1853f5efb60fdc7dd72d2dc8

