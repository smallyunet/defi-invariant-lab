// contracts/flash/FlashArbBorrower.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFlashBorrower} from "./FlashLender.sol";
import {SimpleAMM} from "../amm/SimpleAMM.sol";

contract FlashArbBorrower is IFlashBorrower {
    address public immutable owner;
    address public immutable lender;
    IERC20 public immutable usdc; // token0
    IERC20 public immutable weth; // token1
    SimpleAMM public immutable poolCheap; // Pool where WETH is cheap (USDC->WETH)
    SimpleAMM public immutable poolExpensive; // Pool where WETH is expensive (WETH->USDC)

    event Profit(uint256 profitUSDC);

    constructor(
        address _lender,
        address _usdc,
        address _weth,
        address _poolCheap,
        address _poolExpensive
    ) {
        owner = msg.sender;
        lender = _lender;
        usdc = IERC20(_usdc);
        weth = IERC20(_weth);
        poolCheap = SimpleAMM(_poolCheap);
        poolExpensive = SimpleAMM(_poolExpensive);

        // Set max approvals in advance to avoid repeated costs in callback
        usdc.approve(_poolCheap, type(uint256).max);
        weth.approve(_poolExpensive, type(uint256).max);
    }

    // Start arbitrage from external call
    function execute(uint256 amountUSDC) external {
        require(msg.sender == owner, "only owner");
        // Call the lender
        (bool ok, ) = lender.call(
            abi.encodeWithSignature(
                "flashLoan(address,address,uint256,bytes)",
                address(this),
                address(usdc),
                amountUSDC,
                bytes("") // Can include minOut or other data if needed
            )
        );
        require(ok, "flashLoan failed");
    }

    // Callback from the lender
    function onFlashLoan(
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata
    ) external returns (bytes32) {
        require(msg.sender == lender, "bad lender");
        require(token == address(usdc), "token != USDC");

        // Step1: In the cheap pool, swap USDC -> WETH
        uint256 wethOut = poolCheap.swap0For1(amount);

        // Step2: In the expensive pool, swap WETH -> USDC
        uint256 usdcBack = poolExpensive.swap1For0(wethOut);

        // Step3: Repay loan with interest
        uint256 repay = amount + fee;
        require(usdcBack >= repay, "no profit");
        require(usdc.transfer(lender, repay), "repay fail");

        // Step4: Transfer profit to the deployer
        uint256 profit = usdcBack - repay;
        if (profit > 0) {
            require(usdc.transfer(owner, profit), "payout fail");
            emit Profit(profit);
        }

        return keccak256("IFlashBorrower.onFlashLoan");
    }
}
