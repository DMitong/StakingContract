// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

contract StakingContract {
    using SafeMath for uint256;

    IUniswapV2Router02 private uniswapRouter;
    IWETH private weth;
    ERC20 private DMitongToken;

    uint256 private constant APR = 14;
    uint256 private constant COMPOUNDING_FEE = 1; // 1% compounding fee per month

    mapping(address => uint256) private balances;
    mapping(address => uint256) private earnedTokens;
    uint256 public totalAutoCompoundingFees;
    uint256 public autoCompoundingFeeRate = 1;

    event Stake(address indexed user, uint256 amount);
    event Compound(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(
        address _uniswapRouter,
        address _weth,
        address _DMitongToken
    ) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        weth = IWETH(_weth);
        receiptToken = ERC20(_DMitongToken);
    }

    // Function to stake ETH and mint receipt tokens
    function stake() external payable {
        require(msg.value > 0, "Invalid amount");

        uint256 wethAmount = _convertEthToWeth(msg.value);

        uint256 receiptTokenAmount = _calculateReceiptTokenAmount(wethAmount);
        receiptToken.mint(msg.sender, receiptTokenAmount);

        balances[msg.sender] = balances[msg.sender].add(msg.value);
        earnedTokens[msg.sender] = earnedTokens[msg.sender].add(receiptTokenAmount);

        emit Stake(msg.sender, msg.value);
    }

    // Function to opt in for auto compounding
    function optInAutoCompounding() external {
        uint256 fee = (balances[msg.sender] * autoCompoundingFeeRate) / 100;
        balances[msg.sender] = balances[msg.sender].sub(fee);
        earnedTokens[msg.sender] = earnedTokens[msg.sender].add(fee);
    }

    // Function to trigger auto compounding
    function triggerAutoCompounding() external {
        uint256 reward = (totalAutoCompoundingFees * 10) / 100; // 10% reward
        totalAutoCompoundingFees = totalAutoCompoundingFees.sub(reward);
        earnedTokens[msg.sender] = earnedTokens[msg.sender].add(reward);

        // Perform the auto compounding logic here (convert earned tokens to WETH and stake them)
        // ...

        emit Compound(msg.sender, reward);
    }

    // Function to withdraw
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(amount);

        // Transfer staked WETH and earned tokens
        weth.deposit{value: amount}();
        weth.transfer(msg.sender, amount);
        receiptToken.transfer(msg.sender, earnedTokens[msg.sender]);

        earnedTokens[msg.sender] = 0;

        emit Withdraw(msg.sender, amount);
    }

    // Internal function to convert ETH to WETH
    function _convertEthToWeth(uint256 ethAmount) private returns (uint256) {
        require(ethAmount > 0, "Invalid ETH amount");
        weth.deposit{value: ethAmount}();
        return ethAmount;
    }

    // Internal function to calculate receipt token amount
    function _calculateReceiptTokenAmount(uint256 wethAmount) private view returns (uint256) {
        // You need to implement a method to calculate the proportionate receipt tokens based on the WETH amount and tokenX price.
        // For simplicity, we'll use a placeholder calculation here.
        // uint256 tokenXPrice = ...; // Get the current tokenX price
        // return (wethAmount * 1e18) / (tokenXPrice * 10); // Assuming 1:10 ratio
        return wethAmount * 10; // Placeholder calculation
    }
}
