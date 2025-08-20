// test/invariants/amm/SimpleAMM.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "contracts/amm/SimpleAMM.sol";
import "contracts/libs/TestERC20.sol";

contract SimpleAMMTest is Test {
    SimpleAMM amm;
    TestERC20 token0;
    TestERC20 token1;

    address user = address(0x1);

    function setUp() public {
        token0 = new TestERC20("Token0", "TK0", 18);
        token1 = new TestERC20("Token1", "TK1", 18);
        amm = new SimpleAMM(IERC20(address(token0)), IERC20(address(token1)), 30);

        token0.mint(user, 1e18);
        token1.mint(user, 1e18);

        vm.startPrank(user);
        token0.approve(address(amm), type(uint256).max);
        token1.approve(address(amm), type(uint256).max);
        vm.stopPrank();
    }

    function testAddLiquidity() public {
        vm.startPrank(user);
        amm.addLiquidity(1e17, 2e17);
        (uint112 r0, uint112 r1) = amm.getReserves();
        assertEq(r0, 1e17);
        assertEq(r1, 2e17);
        vm.stopPrank();
    }

    function testSwap0For1() public {
        vm.startPrank(user);
        amm.addLiquidity(1e17, 2e17);
        uint256 out = amm.swap0For1(1e16);
        assertGt(out, 0);
        vm.stopPrank();
    }

    function testSwap1For0() public {
        vm.startPrank(user);
        amm.addLiquidity(1e17, 2e17);
        uint256 out = amm.swap1For0(1e16);
        assertGt(out, 0);
        vm.stopPrank();
    }
}