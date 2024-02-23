# The GREENLERS PROJECT

# Introduction

The GreenlersAdmin contract is a smart contract deployed on the Ethereum blockchain, designed to manage token sales for the Greenlers project. It utilizes the Solidity programming language and leverages several libraries from OpenZeppelin and Chainlink for security and functionality.


## Contract Features

### Sale Management:

- Create new token sales with customizable details (buy/sell price, tokens to sell, payment options).
- Update existing sales by modifying token address, price, payout address, and purchase options.
- Pause and unpause individual sales for maintenance or control purposes.

### Purchase and Sales:

- Users can buy tokens using either ETH or USDT, depending on the sale configuration.
- Users can sell Greenlers tokens back to the contract in exchange for ETH or USDT.

### Security and Control:

- Access control ensures only authorized users can manage sales.
- Reentrancy protection prevents malicious attacks exploiting re-entrancy vulnerabilities.
- Ownership is restricted to prevent accidental or unauthorized contract abandonment.

## Contract Variables

- `saleId`: Unique identifier for each sale.
- `BASE_MULTIPLIER`: Conversion factor for ETH/USD price calculations.
- `sale`: Mapping of sale details (token address, price, remaining tokens, etc.) for each `saleId`.
- `paused`: Mapping of `saleId` to their paused status (true/false).
- `USDTInterface`: Interface for the USDT token contract.
- `aggregatorInterface`: Interface for the Chainlink oracle providing ETH/USD price.

## Contract Functions

### Sale Management:

- `createSale(address _saleTokenAddress, uint256 _buyPrice, uint256 _sellPrice, uint256 _tokensToSell, uint256 _baseDecimals, uint256 _enableBuyWithEth, uint256 _enableBuyWithUsdt, address _payout)`: Creates a new sale with specified details.
- `changeOracleAddress(address _newAddress)`: Updates the Chainlink oracle address.
- `changeUsdtAddress(address _newAddress)`: Updates the USDT token address.
- `changeSaleTokenAddress(uint256 _id, address _newAddress)`: Updates the token address for a specific sale.
- `changePayoutAddress(uint256 _id, address _newAddress)`: Updates the payout address for a specific sale.
- `changeBuyPrice(uint256 _id, uint256 _newPrice)`: Updates the buy price for a specific sale.
- `changeSellPrice(uint256 _id, uint256 _newPrice)`: Updates the sell price for a specific sale.
- `changeEnableBuyWithEth(uint256 _id, uint256 _enableToBuyWithEth)`: Enables/disables buying with ETH for a specific sale.
- `changeEnableBuyWithUsdt(uint256 _id, uint256 _enableToBuyWithUsdt)`: Enables/disables buying with USDT for a specific sale.
- `pauseSale(uint256 _id)`: Pauses a specific sale.
- `unPauseSale(uint256 _id)`: Unpauses a specific sale.
- `getLatestPrice()`: Retrieves the latest ETH/USD price from the oracle.

### Purchase and Sales:

- `buyWithUSDT(uint256 _id, uint256 amount)`: Purchases tokens using USDT for a specific sale.
- `buyWithEth(uint256 _id, uint256 amount)`: Purchases tokens using ETH for a specific sale.
- `sellGreenForEth(uint256 _id, uint256 amount)`: Sells Greenlers tokens for ETH for a specific sale.
- `sellGreenForUSD(uint256 _id, uint256 amount)`: Sells Greenlers tokens for USDT for a specific sale.

### Helper Functions:

- `ethBuyHelper(uint256 _id, uint256 amount)`: Calculates the ETH amount required to buy a specific quantity of tokens.
- `ethSellHelper(uint256 _id, uint256 amount)`: Calculates the ETH amount received for selling a specific quantity of tokens.
- `usdtBuyHelper(uint256 _id, uint256 amount)`: Calculates the USDT amount required to buy a specific quantity of tokens.
- `usdtSellHelper(uint256 _id, uint256 amount)`: Calculates the USDT amount received for selling a specific quantity of tokens.


# Greenlers Staking

# GreenlersStaking Contract Documentation

## Introduction

The GreenlersStaking contract is a smart contract deployed on the Ethereum blockchain, designed for staking tokens and earning rewards. It allows users to stake tokens in designated pools and claim rewards based on their contributions. This document provides an overview of the contract structure, functionalities, and usage guidelines.

## License

This contract is licensed under GPL-3.0.

## Contract Overview

- **Solidity Version:** >=0.8.19 <0.9.0
- **Dependencies:**
  - OpenZeppelin Contracts
  - @openzeppelin/contracts/token/ERC20/IERC20.sol
  - @openzeppelin/contracts/utils/Address.sol
  - @openzeppelin/contracts/utils/Context.sol
  - @openzeppelin/contracts/access/Ownable.sol

## Contract Variables

- `stakeId`: Unique identifier for each staking pool.
- `BASE_MULTIPLIER`: Conversion factor for token decimals.
- `USDTInterface`: Interface for the USDT token contract.
- `paused`: Mapping of staking pool IDs to their paused status.
- `stakePool`: Mapping of staking pool details including stake token, reward token, reward amount, time intervals, and more.
- `stakers`: Mapping of stakers' details including staked amount, claimed amount, and claim start time.

## Events

- `StakePoolCreated`: Emitted when a new staking pool is created.
- `StakePoolUpdated`: Emitted when a stake pool parameter is updated.
- `TokensStaked`: Emitted when tokens are staked by a user.
- `TokensWithdrawn`: Emitted when tokens are withdrawn by a user.
- `TokensClaimed`: Emitted when tokens are claimed by a user.
- `PoolStakeTokenAddressUpdated`: Emitted when the stake token address is updated.
- `PoolRewardTokenAddressUpdated`: Emitted when the reward token address is updated.
- `PoolRewardAmountUpdated`: Emitted when the reward amount in a stake pool is updated.
- `StakePoolPaused`: Emitted when a stake pool is paused.
- `StakePoolUnPaused`: Emitted when a stake pool is unpaused.

## Constructor

- **Parameters:**
  - `_usdt`: USDT token contract address.

## Functions

### Staking Pool Management

- `createPool`: Creates a new staking pool.
- `updatePoolReward`: Updates the reward amount of a staking pool.
- `changeUsdtAddress`: Updates the USDT token address.
- `changeSaleTimes`: Updates the start and end times of a staking pool.
- `changePoolEndtime`: Updates the end time of a staking pool.
- `changeVestingStartTime`: Updates the vesting start time of a staking pool.
- `changeStakeTokenAddress`: Updates the stake token address of a staking pool.
- `changeRewardTokenAddress`: Updates the reward token address of a staking pool.
- `pauseStakePool`: Pauses a staking pool.
- `unPauseStakePool`: Unpauses a staking pool.

### Staking and Claiming

- `stake`: Allows users to stake tokens in a staking pool.
- `claim`: Allows users to claim rewards from a staking pool.
- `withdraw`: Allows users to withdraw staked tokens from a staking pool.
- `claimMultipleAccounts`: Allows batch claiming of rewards for multiple users.
- `claimMultipleStakePools`: Allows batch claiming of rewards from multiple staking pools.
- `withdrawBatch`: Allows batch withdrawal of staked tokens from multiple staking pools.

### Helper Functions

- `rescueETH`: Allows the owner to withdraw ETH sent to the contract.
- `rescueAnyERC20Tokens`: Allows the owner to withdraw any ERC20 tokens sent to the contract.
- `receive`: Fallback function to receive ETH.

## Security Considerations

- Use only trusted addresses for stake and reward tokens.
- Ensure proper configuration of start and end times to prevent unexpected behavior.
- Regularly monitor contract balance and activity.

## Disclaimer

- Use the contracts at your own risk.
- Perform thorough testing and audit before deploying in a production environment.


## Development

This project was developed with hardhat and also integrating other tools commonly used alongside Hardhat in the ecosystem.

The project comes with  a test for that contract, a script that deploys the contract. It also comes with a variety of other tools, preconfigured to work with the project code.

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat run scripts/deploy.ts
TS_NODE_FILES=true npx ts-node scripts/deploy.ts
npx eslint '**/*.{js,ts}'
npx eslint '**/*.{js,ts}' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
```

# Etherscan verification

To try out Etherscan verification, you first need to deploy a contract to an Ethereum network that's supported by Etherscan, such as Ropsten.

In this project, copy the .env.example file to a file named .env, and then edit it to fill in the details. Enter your Etherscan API key, your Ropsten node URL (eg from Alchemy), and the private key of the account which will send the deployment transaction. With a valid .env file in place, first deploy your contract:

```shell
hardhat run --network ropsten scripts/sample-script.ts
```

Then, copy the deployment address and paste it in to replace `DEPLOYED_CONTRACT_ADDRESS` in this command:

```shell
npx hardhat verify --network ropsten DEPLOYED_CONTRACT_ADDRESS "Hello, Hardhat!"
```

# Performance optimizations

For faster runs of your tests and scripts, consider skipping ts-node's type checking by setting the environment variable `TS_NODE_TRANSPILE_ONLY` to `1` in hardhat's environment. For more details see [the documentation](https://hardhat.org/guides/typescript.html#performance-optimizations).
