// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Metadata is IERC20 { function decimals() external view returns (uint8); }

interface IOracle { function latest() external view returns (uint256 price, uint256 ts); }

contract SimpleLending {
    IERC20 public collateral;
    IERC20 public debt;
    IOracle public oracle;

    uint8  public collDec;
    uint8  public debtDec;

    uint256 public LTV_BPS = 7000;       // 70%
    uint256 public LIQ_THRESHOLD = 7500; // 75%
    uint256 public RATE_APY_BPS = 500;   // 5% APY
    uint256 public lastAccrual;
    uint256 public totalBorrows;

    mapping(address => uint256) public coll;
    mapping(address => uint256) public borrows;

    constructor(IERC20 _c, IERC20 _d, IOracle _o) {
        collateral = _c; debt = _d; oracle = _o; lastAccrual = block.timestamp;
        collDec = IERC20Metadata(address(_c)).decimals();
        debtDec = IERC20Metadata(address(_d)).decimals();
    }

    function deposit(uint256 amt) external {
        collateral.transferFrom(msg.sender, address(this), amt);
        coll[msg.sender] += amt;
    }

    function _accrue() internal {
        uint256 dt = block.timestamp - lastAccrual;
        if (dt == 0 || totalBorrows == 0) { lastAccrual = block.timestamp; return; }
        uint256 interest = totalBorrows * RATE_APY_BPS * dt / (365 days) / 10_000;
        totalBorrows += interest;
        lastAccrual = block.timestamp;
    }

    function borrow(uint256 amt) external {
        _accrue();
        require(_value(coll[msg.sender]) * LTV_BPS / 10_000 >= borrows[msg.sender] + amt, "exceeds LTV");
        borrows[msg.sender] += amt;
        totalBorrows += amt;
        debt.transfer(msg.sender, amt);
    }

    function repay(uint256 amt) external {
        _accrue();
        debt.transferFrom(msg.sender, address(this), amt);
        uint256 owed = borrows[msg.sender];
        uint256 pay = amt > owed ? owed : amt;
        borrows[msg.sender] = owed - pay;
        totalBorrows -= pay;
    }

    function liquidate(address user, uint256 repayAmt) external {
        _accrue();
        require(_health(user) < 1e18, "healthy");
        debt.transferFrom(msg.sender, address(this), repayAmt);
        uint256 seize = repayAmt * 11 / 10; // 10% bonus
        if (seize > coll[user]) seize = coll[user];
        coll[user] -= seize;
        borrows[user] -= repayAmt > borrows[user] ? borrows[user] : repayAmt;
        totalBorrows -= repayAmt > totalBorrows ? totalBorrows : repayAmt;
        collateral.transfer(msg.sender, seize);
    }

    // px = debt per 1 collateral (token-level), scaled by 1e8
    function _value(uint256 cAmt) internal view returns (uint256) {
        (uint256 px,) = oracle.latest(); // 1e8 scale, price of 1 collateral token in debt tokens
        // cAmt * px/1e8 * 10^(debtDec - collDec)
        if (debtDec >= collDec) {
            uint256 scale = 10 ** (debtDec - collDec);
            return cAmt * px * scale / 1e8;
        } else {
            uint256 scale = 10 ** (collDec - debtDec);
            return cAmt * px / 1e8 / scale;
        }
    }

    function health(address user) external view returns (uint256) { return _health(user); }
    function _health(address user) internal view returns (uint256) {
        uint256 collV = _value(coll[user]);
        if (borrows[user] == 0) return type(uint256).max;
        return (collV * 10_000 / LIQ_THRESHOLD) * 1e18 / borrows[user];
    }
}
