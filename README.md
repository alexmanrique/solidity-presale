# Presale Contract

A multi-phase presale smart contract built with Foundry that allows users to purchase tokens using USDT, USDC, WETH, or ETH.

## Overview

The Presale contract manages a token presale with the following features:

- **Multi-phase presale**: Supports up to 3 phases with different pricing tiers
- **Multiple payment methods**: Accepts USDT, USDC, WETH, or ETH as payment
- **Time-based phases**: Automatic phase progression based on time or token amount sold
- **Blacklist functionality**: Owner can blacklist/remove addresses from participating
- **User balance tracking**: Tracks token balances for each participant
- **Token claiming**: Users must claim their purchased tokens after the presale ends
- **Chainlink price feed integration**: Uses Chainlink aggregator for ETH/USD price conversion
- **Emergency controls**: Owner can withdraw tokens or ETH in emergency situations

## Contract Features

### Phase Management

- Each phase contains: `[minAmount, price, endTime]`
- Phases automatically advance when:
  - The minimum amount for the phase is reached, OR
  - The phase end time is reached

### Purchase Functionality

- Users can buy tokens using:
  - **USDT** (6 decimals) via `buyWithStable()`
  - **USDC** (6 decimals) via `buyWithStable()`
  - **WETH** (18 decimals) via `buyWithStable()`
  - **ETH** (native) via `buyWithEth()` - uses Chainlink price feed for USD conversion
- Supports tokens with different decimal places (6 for USDC/USDT, 18 for WETH/standard ERC20)
- Automatic price calculation based on current phase
- Enforces maximum selling amount limit
- Tokens are not immediately transferred; users must claim them after the presale ends

### Access Control

- Owner-only functions for blacklist management and emergency withdrawals
- Time-gated presale (between `startingTime` and `endingTime`)

### Token Claiming

- Users can claim their purchased tokens after the presale ends using `claimTokens()`
- Tokens are held in the contract until claimed
- Users must have a balance greater than 0 to claim

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Presale.s.sol:PresaleScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

## Contract Constructor Parameters

When deploying the Presale contract, you need to provide:

- `saleTokenAddress_`: Address of the token being sold (must approve the contract for `maxSellingAmount_`)
- `usdtAddress_`: Address of the USDT token contract
- `usdcAddress_`: Address of the USDC token contract
- `wethAddress_`: Address of the WETH token contract
- `fundsReceiverAddress_`: Address that will receive the payment tokens (USDT/USDC/WETH) and ETH
- `dataFeedAddress_`: Address of the Chainlink ETH/USD price feed aggregator
- `maxSellingAmount_`: Maximum amount of tokens that can be sold (must be transferred to contract during deployment)
- `phases_`: Array of 3 phases, each containing `[minAmount, price, endTime]`
  - `minAmount`: Minimum token amount sold to advance to next phase (in token decimals)
  - `price`: Price per token in USD (scaled by 1e6, e.g., 5000 = $0.005)
  - `endTime`: Unix timestamp when the phase ends
- `startingTime_`: Unix timestamp when the presale starts
- `endingTime_`: Unix timestamp when the presale ends

**Note**: The contract will automatically transfer `maxSellingAmount_` tokens from the deployer to itself during construction. Ensure the deployer has approved the contract for this amount.

## Security Considerations

- The contract uses OpenZeppelin's `Ownable` for access control
- `SafeERC20` is used for all token transfers to prevent reentrancy
- Blacklist functionality allows owner to prevent specific addresses from participating
- Emergency withdrawal functions allow owner to recover funds if needed
- Tokens are held in escrow until users claim them after the presale ends
- Phase progression is automatic and cannot be manipulated by users
- Price feed integration ensures accurate ETH/USD conversion for native ETH purchases
