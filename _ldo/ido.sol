
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Myerc20 is ERC20{
    constructor() ERC20 ("aave","AAve"){

    }
    function mint(address _to,uint256 _amount) public {
        _mint(_to,_amount);
    }
}

contract ido  {
    
    IERC20 public token;
    uint256 public Total;
    address public owner;

    uint256 public price;
    uint256 public TOTAL_RAISE;
    uint256 public startTime;
    uint256 public deadline;

    mapping(address => uint256) public UserTotal;


    // 10000

    constructor(address _token,uint256 _price,uint256 _TOTAL_RAISE,uint256 _deadline) {
        token = IERC20(_token);
        price = _price;
        TOTAL_RAISE = _TOTAL_RAISE;

        // 记录合约部署时的区块时间戳
        startTime = block.timestamp;
        deadline = block.timestamp + _deadline;
        owner = msg.sender;

    }

    
    function preSale() public payable onTime maxSale{
        require(msg.value > 0,"ether to low");
        uint256 amount = msg.value / price;
        Total += msg.value;
        UserTotal[msg.sender] += amount;
    }

    modifier onTime(){
        require(block.timestamp < deadline,"Time is up");
        _;
    }

    modifier maxSale(){
        require(msg.value <= (TOTAL_RAISE - Total),"Exceeding the maximum");
    
        require(Total <= TOTAL_RAISE,"Oversubscription");
        _;
    }

    function Presalerefund() public {
        require(block.timestamp >= deadline,"Time is up");
        require(Total < TOTAL_RAISE, "Pre-sale success");
        uint256 amount = UserTotal[msg.sender] * price;
        UserTotal[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }


    function UserTokenClaim() public {
        require(block.timestamp >= deadline && Total >= TOTAL_RAISE, "Pre-sale not successful");
        uint256 amount = UserTotal[msg.sender];
        UserTotal[msg.sender] = 0;
        token.transfer(msg.sender,amount);
    }


    function devClaim() public{
        require(msg.sender == owner,"You are not the owner");
        require(block.timestamp >= deadline,"Time is not up");
        require(Total >= TOTAL_RAISE,"Pre-sale success");
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBlock () public view  returns(uint256){
        return block.timestamp;
    }
}
