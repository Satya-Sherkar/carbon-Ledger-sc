# Carbon Marketplace

A blockchain-powered decentralized marketplace for transparent and efficient carbon credit trading, built with Solidity smart contracts and the Foundry development framework.

## Overview

Carbon Marketplace is a Web3 platform that enables the tokenization, trading, and management of carbon credits on the Ethereum blockchain. The project implements ERC20-compliant carbon credit tokens and a marketplace contract that facilitates secure, transparent trading of carbon offsets.

## Features

### Carbon Credit Tokenization

- ERC20-compatible carbon credit tokens for standardized representation
- Immutable on-chain provenance tracking


### Marketplace Functionality

- Decentralized trading platform for carbon credits
- Smart contract-driven listing and trading mechanisms
- Sell and halt listing functionality for token management
- Transparent transaction history


### Security \& Verification

- Only Auditor function checks ensuring carbon credits meet required standards
- Blockchain-based audit trail for all transactions


## Tech Stack

- **Smart Contracts:** Solidity
- **Development Framework:** Foundry (Forge, Cast, Anvil)
- **Testing:** Foundry testing framework 
- **Blockchain:** Ethereum-compatible networks

## Project Structure

```
carbon-marketplace/
├── src/              # Smart contracts
├── test/             # Test files
├── script/           # Deployment scripts
├── lib/              # Dependencies
└── foundry.toml      # Foundry configuration
```


## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Git for version control


### Installation

1. Clone the repository:
```bash
git clone https://github.com/Satya-Sherkar/carbon-marketplace.git
cd carbon-marketplace
```

2. Install dependencies:
```bash
forge install
```

3. Build the contracts:
```bash
forge build
```


### Running Tests

Execute the test suite:

```bash
forge test
```

Run tests with verbosity:

```bash
forge test -vvv
```

Generate coverage report:

```bash
forge coverage
```


### Deployment

Deploy to a local testnet:

```bash
anvil
forge script script/Deploy.s.sol --rpc-url < YOUR_RPC_URL_HERE > --broadcast
```


## Smart Contracts

### CarbonCreditToken

ERC20 token contract representing carbon credits with minting and burning capabilities.

### Marketplace

Core marketplace contract handling listing creation, trading execution, and listing management.


## Contributing

Contributions are welcome! Please follow these steps :

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request


## Contact

**Developer:** Satya Sherkar
**GitHub:** [@Satya-Sherkar](https://github.com/Satya-Sherkar)
**Repository:** [carbon-marketplace](https://github.com/Satya-Sherkar/carbon-marketplace)

## Acknowledgments

- Built with [Foundry](https://getfoundry.sh/)
- Inspired by global carbon credit market initiatives
- Contributing to environmental sustainability through blockchain technology

***

**Environmental Commitment:** Empowering transparent carbon credit trading to accelerate global carbon reduction efforts.
