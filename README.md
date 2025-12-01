# Presale Contract

A multi-phase presale smart contract built with Foundry that allows users to purchase tokens using USDT or USDC stablecoins.

## Overview

The Presale contract manages a token presale with the following features:

- **Multi-phase presale**: Supports up to 3 phases with different pricing tiers
- **Dual stablecoin support**: Accepts both USDT and USDC as payment
- **Time-based phases**: Automatic phase progression based on time or token amount sold
- **Blacklist functionality**: Owner can blacklist/remove addresses from participating
- **User balance tracking**: Tracks token balances for each participant
- **Emergency controls**: Owner can withdraw tokens or ETH in emergency situations

## Contract Features

### Phase Management

- Each phase contains: `[minAmount, price, endTime]`
- Phases automatically advance when:
  - The minimum amount for the phase is reached, OR
  - The phase end time is reached

### Purchase Functionality

- Users can buy tokens using USDT or USDC
- Supports tokens with different decimal places (6 for USDC/USDT, 18 for standard ERC20)
- Automatic price calculation based on current phase
- Enforces maximum selling amount limit

### Access Control

- Owner-only functions for blacklist management and emergency withdrawals
- Time-gated presale (between `startingTime` and `endingTime`)

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

- `usdtAddress_`: Address of the USDT token contract
- `usdcAddress_`: Address of the USDC token contract
- `fundsReceiverAddress_`: Address that will receive the stablecoin payments
- `maxSellingAmount_`: Maximum amount of tokens that can be sold
- `phases_`: Array of 3 phases, each containing `[minAmount, price, endTime]`
- `startingTime_`: Unix timestamp when the presale starts
- `endingTime_`: Unix timestamp when the presale ends

## Security Considerations

- The contract uses OpenZeppelin's `Ownable` for access control
- `SafeERC20` is used for all token transfers to prevent reentrancy
- Blacklist functionality allows owner to prevent specific addresses from participating
- Emergency withdrawal functions allow owner to recover funds if needed
