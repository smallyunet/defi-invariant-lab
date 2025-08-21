// contracts/flash/FlashLender.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFlashBorrower {
    function onFlashLoan(address token, uint256 amount, uint256 fee, bytes calldata data)
        external
        returns (bytes32);
}

contract FlashLender {
    uint16 public immutable feeBps; // e.g. 5 = 0.05%
    address public immutable owner;

    event FlashLoan(address indexed receiver, address indexed token, uint256 amount, uint256 fee);

    constructor(uint16 _feeBps) {
        feeBps = _feeBps;
        owner = msg.sender;
    }

    function flashLoan(address receiver, address token, uint256 amount, bytes calldata data) external {
        IERC20 t = IERC20(token);
        uint256 balBefore = t.balanceOf(address(this));
        require(balBefore >= amount, "insufficient liquidity");

        uint256 fee = (amount * feeBps) / 10_000;

        // send
        require(t.transfer(receiver, amount), "transfer out");

        // callback
        bytes32 magic = IFlashBorrower(receiver).onFlashLoan(token, amount, fee, data);
        require(magic == keccak256("IFlashBorrower.onFlashLoan"), "bad callback");

        // must be repaid (principal + fee)
        uint256 balAfter = t.balanceOf(address(this));
        require(balAfter >= balBefore + fee, "not repaid");

        emit FlashLoan(receiver, token, amount, fee);
    }

    // Simple funding interface (deposit funds as lendable pool)
    function fund(address token, uint256 amt) external {
        require(IERC20(token).transferFrom(msg.sender, address(this), amt), "fund fail");
    }
}
