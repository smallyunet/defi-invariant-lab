// contracts/oracle/MedianOracle.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MedianOracle {
    struct Feed { bool active; }
    mapping(address => Feed) public feeders;
    uint256 public cooldown = 30; // sec
    uint256 public lastTs;
    uint256 public lastPrice; // 1e8

    modifier onlyFeeder() { require(feeders[msg.sender].active, "not feeder"); _; }

    function setFeeder(address a, bool on) external { feeders[a].active = on; }

    function post(uint256[] calldata prices) external onlyFeeder {
        require(block.timestamp >= lastTs + cooldown, "cooldown");
        require(prices.length > 0, "empty");
        uint256 med = _median(prices);
        lastPrice = med;
        lastTs = block.timestamp;
    }

    function latest() external view returns (uint256 price, uint256 ts) { return (lastPrice, lastTs); }

    function _median(uint256[] calldata arr) internal pure returns (uint256) {
        // Simplified: Assume that the order is already sorted; in real implementation, sort and take the median
        return arr[arr.length/2];
    }
}
