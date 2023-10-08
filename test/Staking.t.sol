// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.21;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/utils/math/Math.sol";
// import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
// import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
// import {Test, console2} from "forge-std/Test.sol";
// import {StakingContract} from "../src/Staking.sol";

// contract StakingContractTest is Test {
//     using Math for uint256;

//     IUniswapV2Router02 private uniswapRouter;
//     IWETH private weth;
//     ERC20 private WDMitongToken;
//     ERC20 private DMitongToken;
//     StakingContract private stakingContract;

//     // Set up the test environment
//     function setUp() public {
//         uniswapRouter = IUniswapV2Router02(
//             0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
//         );
//         weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
//         WDMitongToken = new ReceiptToken();
//         DMitongToken = new RewardToken();
//         stakingContract = new StakingContract();
//     }

//     // Test the stake function with ETH
//     function testStakeEth() public {
//         // Send 1 ether to the staking contract
//         stakingContract.stake{value: 1 ether}();

//         // Check that the balance and earned tokens are updated correctly
//         assertEq(stakingContract.balances(address(this)), 1 ether);
//         assertEq(stakingContract.earnedTokens(address(this)), 10 ether);

//         // Check that the receipt token is minted correctly
//         assertEq(WDMitongToken.balanceOf(address(this)), 10 ether);
//     }

//     // Test the stake function with WDMitongToken
//     function testStakeWDMitongToken() public {
//         // Mint some WDMitongToken for testing
//         WDMitongToken.mint(address(this), 100 ether);

//         // Approve the staking contract to spend WDMitongToken
//         WDMitongToken.approve(address(stakingContract), 100 ether);

//         // Deposit 50 ether worth of WDMitongToken to the staking contract
//         stakingContract.deposit(50 ether);

//         // Check that the balance and earned tokens are updated correctly
//         assertEq(stakingContract.balances(address(this)), 50 ether);
//         assertEq(stakingContract.earnedTokens(address(this)), 50 ether);

//         // Check that the receipt token is transferred correctly
//         assertEq(WDMitongToken.balanceOf(address(this)), 50 ether);
//     }

//     // Test the opt-in auto compounding function
//     function testOptInAutoCompounding() public {
//         // Stake some ETH first
//         stakingContract.stake{value: 1 ether}();

//         // Opt in for auto compounding
//         stakingContract.optInAutoCompounding();

//         // Check that the balance is reduced by the fee rate
//         assertEq(stakingContract.balances(address(this)), 0.99 ether);

//         // Check that the earned tokens are increased by the fee amount
//         assertEq(stakingContract.earnedTokens(address(this)), 10.01 ether);
//     }

//     // Test the trigger auto compounding function
//     function testTriggerAutoCompounding() public {
//         // Stake some ETH first
//         stakingContract.stake{value: 1 ether}();

//         // Opt in for auto compounding
//         stakingContract.optInAutoCompounding();

//         // Trigger auto compounding and get a reward
//         stakingContract.triggerAutoCompounding();

//         // Check that the reward is 10% of the total fees
//         assertEq(
//             stakingContract.earnedTokens(address(this)),
//             10.01 ether + (0.01 ether).mul(10).div(100)
//         );

//         // Check that the balance is increased by the swapped WETH amount
//         uint256 wethReward = uniswapRouter.getAmountsOut(
//             (0.01 ether).mul(10).div(100),
//             [address(DMitongToken), address(weth)]
//         )[1];
//         assertEq(
//             stakingContract.balances(address(this)),
//             0.99 ether + wethReward
//         );
//     }

//     // Test the withdraw function
//     function testWithdraw() public {
//         // Stake some ETH first
//         stakingContract.stake{value: 1 ether}();

//         // Withdraw the staked amount and the earned tokens
//         stakingContract.withdraw(1 ether);

//         // Check that the balance and earned tokens are zero
//         assertEq(stakingContract.balances(address(this)), 0);
//         assertEq(stakingContract.earnedTokens(address(this)), 0);

//         // Check that the WETH and WDMitongToken are transferred correctly
//         assertEq(weth.balanceOf(address(this)), 1 ether);
//         assertEq(WDMitongToken.balanceOf(address(this)), 10 ether);
//     }

//     // Test the stake function with fuzzing
//     function testStakeFuzz(uint256 ethAmount) public {
//         // Assume that the ethAmount is positive and less than 100 ether
//         assume(ethAmount > 0 && ethAmount < 100 ether);

//         // Stake the ethAmount to the staking contract
//         stakingContract.stake{value: ethAmount}();

//         // Check that the balance and earned tokens are updated correctly
//         assertEq(stakingContract.balances(address(this)), ethAmount);
//         assertEq(
//             stakingContract.earnedTokens(address(this)),
//             ethAmount.mul(10)
//         );
//     }
// }
