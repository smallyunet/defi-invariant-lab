# DeFi Invariant Lab

A research and development laboratory for exploring and testing financial invariants in DeFi protocols. This project includes simple but realistic implementations of key DeFi primitives (AMMs, Lending, Oracles) designed for formal verification and invariant testing.

## Overview

The DeFi Invariant Lab provides minimalist implementations of core DeFi protocols that preserve their essential financial properties. These implementations serve as a foundation for:

- Exploring formal verification techniques in DeFi
- Testing protocol invariants under various market conditions
- Researching vulnerabilities and edge cases in DeFi primitives
- Educational purposes to understand core DeFi mechanisms

## Key Components

### SimpleAMM

A basic Automated Market Maker (AMM) that follows the constant product market maker model (x*y=k). Features:

- Token pair trading with configurable fees
- Liquidity provision mechanisms
- Constant product invariant that maintains price discovery

### SimpleLending

A lending protocol that enables over-collateralized borrowing. Features:

- Collateral deposit and withdrawal
- Variable interest rate borrowing
- Liquidation mechanisms with health factor calculations
- Oracle price integration for collateral valuation

### MedianOracle

A price oracle system that reports asset prices. Features:

- Multiple price feed support
- Median price calculation to resist manipulation
- Configurable price update cooldowns
- Authorization controls for trusted feeders

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org/) (optional, for additional tooling)

### Installation

1. Clone the repository:
```shell
git clone https://github.com/smallyunet/defi-invariant-lab.git
cd defi-invariant-lab
```

2. Install dependencies:
```shell
forge install
```

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Run Invariant Tests

```shell
forge test --match-test invariant_* -vvv
```

## Project Structure

```
contracts/                # Smart contract implementations
├── amm/                  # AMM related contracts
├── lending/              # Lending protocol contracts
├── oracle/               # Price oracle implementations
├── interfaces/           # Contract interfaces
└── libs/                 # Utility libraries

test/                     # Test suite
├── unit/                 # Unit tests
└── invariant/            # Invariant and property-based tests

sims/                     # Simulation frameworks
```

## Financial Invariants

This project focuses on the following key financial invariants:

1. **Constant Product AMM**: Ensuring the k = x * y invariant holds for all trades
2. **Lending Solvency**: Maintaining protocol solvency through proper collateralization
3. **Price Oracle Consistency**: Ensuring price feeds remain within acceptable bounds
4. **Liquidation Conditions**: Verifying liquidation thresholds maintain protocol health

## Development

### Adding New DeFi Primitives

1. Create a new contract in the appropriate subfolder
2. Implement the core financial invariants
3. Add unit tests to verify functionality
4. Add invariant tests to check for edge cases

### Running Simulations

Use Forge's built-in fuzz testing capabilities to run simulations:

```shell
forge test --match-path "test/invariant/*" --fuzz-runs 10000
```

## Foundry Tools

This project uses Foundry, which consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools)
- **Cast**: Swiss army knife for interacting with EVM smart contracts
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network
- **Chisel**: Fast, utilitarian, and verbose solidity REPL

For more information, see the [Foundry Documentation](https://book.getfoundry.sh/)

## Resources

- [Foundry Documentation](https://book.getfoundry.sh/)
- [DeFi Protocol Security](https://defisafety.com/)
- [Formal Verification in DeFi](https://runtimeverification.com/blog/defi-formal-verification)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Foundry](https://github.com/foundry-rs/foundry) for the Ethereum development toolchain
- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts) for security-focused contracts
- [PRB-Math](https://github.com/PaulRBerg/prb-math) for fixed-point math utilities
