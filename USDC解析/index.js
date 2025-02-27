// // const { ethers } = require("ethers"  );
// import { ethers } from "https://cdn.jsdelivr.net/npm/ethers@6.13.5/+esm";
// index.js
import { ethers } from "https://cdn.jsdelivr.net/npm/ethers@6.13.5/+esm";

// 使用默认提供者连接以太坊主网
const provider = ethers.getDefaultProvider(
  "https://eth-mainnet.g.alchemy.com/v2/nOeWCu5iDox9ohhZQ3XU3pP_F59GSe8_"
);

// var provider = new ethers.JsonRpcProvider("https://eth.rpc.blxrbdn.com")

// const address = "0x932BBc319941817C3ed10a3ADcE0DdcC722aE283";

// async function getBlockNumber() {
//     await provider.getBalance(address)
//         .then((balance) => {
//             console.log(`地址 ${address} 的余额为: ${ethers.formatEther(balance)} ETH`);
//         })
//         .catch((error) => {
//             console.log(error);
//         });
// }

// getBlockNumber();

document.addEventListener("DOMContentLoaded", function () {
  // 获取按钮元素
  const walletButton = document.querySelector(".wallet-button");

  // 监听点击事件
  walletButton.addEventListener("click", function () {
    if (window.ethereum != null) {
      // 获取钱包地址
      window.ethereum
        .request({ method: "eth_requestAccounts" })
        .then((accounts) => {
          document.getElementById(
            "balance-address"
          ).innerHTML = `当前钱包地址是：${accounts}`;
          alert("钱包已连接！");
        })
        .catch((error) => {
          console.log(`${error}`);
        });
      return;
    } else {
      alert("钱包没安装！");
    }
  });
});

// 查询当前区块号
document
  .getElementById("btn-current-block")
  .addEventListener("click", async () => {
    try {
      const blockNumber = await provider.getBlockNumber();
      document.getElementById(
        "current-block"
      ).innerText = `当前区块号: ${blockNumber}`;
    } catch (error) {
      document.getElementById(
        "current-block"
      ).innerText = `查询当前区块错误: ${error.message}`;
    }
  });

// 查询地址余额
document
  .getElementById("btn-query-balance")
  .addEventListener("click", async () => {
    const address = document.getElementById("address-input").value.trim();
    if (!address) {
      document.getElementById("balance-result").innerText =
        "请输入有效的以太坊地址";
      return;
    }
    try {
      const balance = await provider.getBalance(address);
      const etherBalance = ethers.formatEther(balance);
      document.getElementById(
        "balance-result"
      ).innerText = `余额: ${etherBalance} ETH`;
    } catch (error) {
      document.getElementById(
        "balance-result"
      ).innerText = `查询余额错误: ${error.message}`;
    }
  });

// ERC20 合约最小 ABI，仅包含 symbol 方法
const ERC20_ABI = ["function symbol() view returns (string)"];

// 查询合约 symbol
document
  .getElementById("btn-query-symbol")
  .addEventListener("click", async () => {
    const contractAddress = document
      .getElementById("contract-input")
      .value.trim();
    if (!contractAddress) {
      document.getElementById("contract-symbol").innerText = "请输入穿的数量";
      return;
    }
    try {
      const contract = new ethers.Contract(
        contractAddress,
        ERC20_ABI,
        provider
      );
      const symbol = await contract.symbol();
      document.getElementById(
        "contract-symbol"
      ).innerText = `合约符号: ${symbol}`;
    } catch (error) {
      document.getElementById(
        "contract-symbol"
      ).innerText = `查询合约符号错误: ${error.message}`;
    }
  });

async function getRecentUSDCTransfers(num) {
  // USDC 合约地址和 Transfer 事件的 ABI
  const usdcAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
  const usdcABI = [
    "event Transfer(address indexed from, address indexed to, uint256 value)",
  ];

  // 创建 USDC 合约实例
  const contract = new ethers.Contract(usdcAddress, usdcABI, provider);

  // 查询最新 100 个 Transfer 事件
  const latestBlock = await provider.getBlockNumber();
  const fromBlock = latestBlock - 1; // 从最近 1000 个区块开始查询
  // console.log("Latest Block:", latestBlock);
  // console.log("From Block:", fromBlock);
  // 查询 Transfer 事件
  const transfers = await contract.queryFilter(
    "Transfer",
    fromBlock,
    latestBlock
  );

  // 输出交易数据
  const recentTransfers = transfers.slice(0, num); // 获取最近 100 条交易
  // console.log("Recent USDC Transfers:", recentTransfers);
  return recentTransfers;
  // 格式化输出每笔交易的详细信息
  recentTransfers.forEach((transfer, index) => {
    console.log(`From: ${transfer.args.from}`);
    console.log(`To: ${transfer.args.to}`);
    console.log(Number(transfer.args.value) / 1000000);
    console.log(`Transaction Hash: ${transfer.transactionHash}`);
    console.log("----------------------------");
  });
}

// var a = getRecentUSDCTransfers(1);
// console.log(a)

async function usdcClick() {
  const queryAmount = document.querySelector(".usdcIpu").value;

  let result = await getRecentUSDCTransfers(queryAmount);
  console.log("查询数量:", queryAmount);
  // let  result = await getRecentUSDCTransfers(queryAmount);
  // console.log(typeof result);
  // console.log(result);

  // 获取表格的 tbody 元素
  const tableBody = document.getElementById("transaction-table-body");

  // 清空之前的查询结果
  tableBody.innerHTML = "";
  result = Object.entries(result);


  result.forEach(([index, log]) => {
    // if(log.topics.length <= 3) {
    //   return;
    // }
    // 创建一个新的 <tr> 行
    console.log(log)
    const row = document.createElement('tr');
  
    // 创建并填充 "From" 单元格
    const fromCell = document.createElement('td');
    fromCell.textContent = log.args.from; 
    
    // 创建并填充 "To" 单元格
    const toCell = document.createElement('td');
    toCell.textContent = log.args.to; 
  
    // 创建并填充 "Amount" 单元格
    const amountCell = document.createElement('td');
    amountCell.textContent = (parseInt(log.data, 16) / 1000000).toFixed(6); 
  
    // 创建并填充 "Transaction Hash" 单元格
    const hashCell = document.createElement('td');
    hashCell.textContent = log.transactionHash;
  
    // 将单元格添加到行
    row.appendChild(fromCell);
    row.appendChild(toCell);
    row.appendChild(amountCell);
    row.appendChild(hashCell);
  
    // 将行添加到表格的 <tbody>
    tableBody.appendChild(row);
  });
  
}

document
  .querySelector("#btn-query-USDCTransfer")
  .addEventListener("click", usdcClick);

$(document).ready(function () {
  $("#example").DataTable();
});
