// contracts/amm/SimpleAMM.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract SimpleAMM {
    IERC20 public immutable token0;
    IERC20 public immutable token1;
    uint16 public immutable feeBps; // e.g. 30 = 0.3%
    uint112 public reserve0;
    uint112 public reserve1;

    error InsufficientInput();
    error TransferFailed();

    constructor(IERC20 _t0, IERC20 _t1, uint16 _feeBps) {
        token0 = _t0;
        token1 = _t1;
        feeBps = _feeBps;
    }

    function _update(uint256 r0, uint256 r1) internal {
        reserve0 = uint112(r0);
        reserve1 = uint112(r1);
    }

    function addLiquidity(uint256 a0, uint256 a1) external {
        if (a0 == 0 || a1 == 0) revert InsufficientInput();
        require(token0.transferFrom(msg.sender, address(this), a0), "t0");
        require(token1.transferFrom(msg.sender, address(this), a1), "t1");
        _update(
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        );
    }

    function swap0For1(uint256 amtIn) external returns (uint256 out) {
        if (amtIn == 0) revert InsufficientInput();
        require(token0.transferFrom(msg.sender, address(this), amtIn), "t0in");
        uint256 r0 = token0.balanceOf(address(this));
        uint256 r1 = token1.balanceOf(address(this));

        uint256 amtInEff = (amtIn * (10_000 - feeBps)) / 10_000;
        // x*y=k, solve out = r1 - k/(r0)
        uint256 k = (r0 - amtInEff) * r1;
        out = r1 - Math.ceilDiv(k, r0); // 向上取整，保守
        require(token1.transfer(msg.sender, out), "t1out");
        _update(
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        );
    }

    function swap1For0(uint256 amtIn) external returns (uint256 out) {
        if (amtIn == 0) revert InsufficientInput();
        require(token1.transferFrom(msg.sender, address(this), amtIn), "t1in");
        uint256 r0 = token0.balanceOf(address(this));
        uint256 r1 = token1.balanceOf(address(this));

        uint256 amtInEff = (amtIn * (10_000 - feeBps)) / 10_000;
        uint256 k = r0 * (r1 - amtInEff);
        out = r0 - Math.ceilDiv(k, r1);
        require(token0.transfer(msg.sender, out), "t0out");
        _update(
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        );
    }

    function getReserves() external view returns (uint112, uint112) {
        return (reserve0, reserve1);
    }
}
