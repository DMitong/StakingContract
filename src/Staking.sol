// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import {ReceiptToken, RewardToken} from "./Tokens.sol";

contract StakingContract {
    using Math for uint256;

    IUniswapV2Router02 public uniswapRouter;
    IWETH public weth;
    ERC20 public WDMitongToken;
    ERC20 public DMitongToken;

    uint256 private constant APR = 14;
    uint256 private constant COMPOUNDING_FEE = 1;

    mapping(address => uint256) private balances;
    mapping(address => uint256) private earnedTokens;
    uint256 public totalAutoCompoundingFees;
    uint256 public autoCompoundingFeeRate = 1;

    event Stake(address indexed user, uint256 amount);
    event Compound(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor() {
        uniswapRouter = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        WDMitongToken = new ReceiptToken();
        DMitongToken = new RewardToken();
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Invalid amount");
        require(
            WDMitongToken.allowance(msg.sender, address(this)) >= amount,
            "Insufficient allowance"
        );
        require(
            WDMitongToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        uint256 WDMitongTokenAmount = amount;

        balances[msg.sender] = balances[msg.sender].tryAdd(amount);
        earnedTokens[msg.sender] = earnedTokens[msg.sender].tryAdd(
            WDMitongTokenAmount
        );

        emit Stake(msg.sender, amount);
    }

    // Function to stake ETH and mint receipt tokens
    function stake() external payable {
        require(msg.value > 0, "Invalid amount");

        uint256 wethAmount = _convertEthToWeth(msg.value);

        uint256 WDMitongTokenAmount = _calculateWDMitongTokenAmount(wethAmount);
        WDMitongToken.mint(msg.sender, WDMitongTokenAmount);

        balances[msg.sender] = balances[msg.sender].tryAdd(msg.value);
        earnedTokens[msg.sender] = earnedTokens[msg.sender].tryAdd(
            WDMitongTokenAmount
        );

        emit Stake(msg.sender, msg.value);
    }

    // Function to opt in for auto compounding
    function optInAutoCompounding() external {
        uint256 fee = (balances[msg.sender].mul(autoCompoundingFeeRate)).tryDiv(
            100
        );
        balances[msg.sender] = balances[msg.sender].trySub(fee);
        earnedTokens[msg.sender] = earnedTokens[msg.sender].tryAdd(fee);
    }

    // Function to trigger auto compounding
    function triggerAutoCompounding() external {
        uint256 reward = (totalAutoCompoundingFees.mul(10)).tryDiv(100); // 10% reward
        totalAutoCompoundingFees = totalAutoCompoundingFees.trySub(reward);
        earnedTokens[msg.sender] = earnedTokens[msg.sender].tryAdd(reward);

        // Perform the auto compounding logic here (convert earned tokens to WETH and stake them)
        // Swap reward tokens to WETH
        uint256 wethReward = swapRewardsToWeth(reward);

        // Add to staked amount
        balances[msg.sender] = balances[msg.sender].tryAdd(wethReward);

        emit Compound(msg.sender, reward);
    }

    // Function to withdraw
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].trySub(amount);

        // Transfer staked WETH and earned tokens
        weth.deposit{value: amount}();
        weth.transfer(msg.sender, amount);
        WDMitongToken.transfer(msg.sender, earnedTokens[msg.sender]);

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
    function _calculateWDMitongTokenAmount(
        uint256 wethAmount
    ) private view returns (uint256) {
        uint256 DMitongTokenPrice = 1 ether / 10; // 0.1 ether per DMitongToken
        uint256 DMitongTokenAmount = wethAmount.mul(DMitongTokenPrice);
        uint256 WDMitongTokens = DMitongTokenAmount.mul(10);

        return WDMitongTokens;
    }

    // Internal function to swap reward tokens to WETH using Uniswap V2 router
    function swapRewardsToWeth(uint256 amount) internal returns (uint256) {
        require(amount > 0, "Invalid reward amount");

        // Approve router to spend reward tokens
        DMitongToken.approve(address(uniswapRouter), amount);

        // Set path of tokens to swap
        address[] memory path = new address[](2);
        path[0] = address(DMitongToken);
        path[1] = address(weth);

        // Swap tokens
        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            amount,
            0, // Accept any amount of WETH
            path,
            address(this), // Send WETH to this contract
            block.timestamp // Deadline
        );

        return amounts[1]; // Return the amount of WETH received
    }
}
