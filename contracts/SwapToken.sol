// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {IERC20} from "./IERC20.sol";


contract SwapToken {
    
    IERC20 public nairaToken;
    IERC20 public usdtToken;
    address owner;
    bool internal locked;
    uint256 internal constant ONE_USDT_TO_NAIRA = 1600;

    enum Currency {NONE, NAIRA, USDT }

mapping (address => uint256)  contractBalances;

    constructor(IERC20 _nairaTokenCAddr, IERC20 _usdtTokenCAddr){
        nairaToken = _nairaTokenCAddr;
        usdtToken = _usdtTokenCAddr;
        owner = msg.sender;
    }

    event SwapSuccessful(address indexed from, address indexed to, uint256 amount);
    event WithdrawSuccessful(address indexed owner, address indexed tokenAddress, uint256 amount);


    modifier reentrancyGuard() {
        require(!locked, "Reentrancy not allowed");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can access");
        _;
    }


    function swapNairaToUsdt(address _from, uint256 _amount) external reentrancyGuard  {
        require(msg.sender != address(0), "Zero not allowed");
        require(_amount > 0 , "Cannot swap zero amount");

        uint256 standardAmount = _amount * 10**18;

        uint256 userBal = nairaToken.balanceOf(msg.sender);

        require(userBal >= _amount, "Your balance is not enough");

        uint256 allowance = nairaToken.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Token allowance too low");


        bool deducted = nairaToken.transferFrom(_from, address(this), standardAmount);

        require(deducted, "Excution failed");



        uint256 convertedValue_ = Naira_Usdt_Rate(standardAmount, Currency.NAIRA);

        bool swapped = usdtToken.transfer(msg.sender, convertedValue_);



        if (swapped) {


            emit SwapSuccessful(_from, address(this), standardAmount );
        }

    }




    function swapUsdtToNaira(address _from, uint256 _amount) external reentrancyGuard {
        require(msg.sender != address(0), "Zero not allowed");
        require(_amount > 0 , "Cannot swap zero amount");

        uint256 standardAmount = _amount * 10**18;

        uint256 userBal = usdtToken.balanceOf(msg.sender);


        require(userBal >= _amount, "Your balance is not enough");

       
        uint256 allowance = usdtToken.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Token allowance too low");


        bool deducted = usdtToken.transferFrom(_from, address(this), standardAmount);

        require(deducted, "Excution failed");



        uint256 convertedValue_ = Naira_Usdt_Rate(standardAmount, Currency.USDT);

        bool swapped = nairaToken.transfer(msg.sender, convertedValue_);

        if (swapped) {


            emit SwapSuccessful(_from, address(this), standardAmount );
        }


    }


        function getContractBalance() external view onlyOwner returns (uint256 contractUsdtbal_, uint256 contractNairabal_) {
        contractUsdtbal_ = usdtToken.balanceOf(address(this));
        contractNairabal_ = nairaToken.balanceOf(address(this));
    }


      function withdraw(address _tokenAddress, uint256 _amount) external onlyOwner reentrancyGuard {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_amount > 0, "balance is less");

        uint256 bal = contractBalances[_tokenAddress];

        require(bal >= _amount, "Insufficient contract balance");

        contractBalances[_tokenAddress] -= _amount;



        IERC20(_tokenAddress).transfer(msg.sender, _amount);

        emit WithdrawSuccessful(msg.sender, _tokenAddress, _amount);
    }

function Naira_Usdt_Rate(uint256 amount, Currency _currency) internal pure returns (uint256 convertedValue) {
    if (_currency == Currency.USDT) {
        convertedValue = amount * ONE_USDT_TO_NAIRA;  // Corrected the variable name
    } else if (_currency == Currency.NAIRA) {
        convertedValue = amount / ONE_USDT_TO_NAIRA;  // Corrected the variable name
    } else {
        revert("Unsupported currency");  // This part is fine
    }
    return convertedValue;
}

}
