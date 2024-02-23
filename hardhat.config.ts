import '@openzeppelin/hardhat-upgrades';
import 'dotenv/config';
import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-waffle';
import '@typechain/hardhat';
import 'hardhat-gas-reporter';
import 'solidity-coverage';
import { HardhatUserConfig } from 'hardhat/config';
import { removeConsoleLog } from 'hardhat-preprocessor';
import { readFileSync } from 'fs';

const privateKey = readFileSync('./private/.secret').toString().trim();

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',

  networks: {
    hardhat: {
      chainId: 1337,
    },
    bsc: {
      chainId: 56,
      url: `https://bsc-dataseed1.binance.org/`,
      accounts: [privateKey],
    },

    goerli: {
      chainId: 5,
      url: `https://eth-goerli.g.alchemy.com/v2/${process.env.MAINNET_RPC}`,
      accounts: [privateKey],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: 'USD',
  },

  etherscan: {
    apiKey: process.env.BSCSCAN_API_KEY,
  },
  solidity: {
    compilers: [
      {
        version: '0.8.19',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  preprocess: {
    eachLine: removeConsoleLog((hre) => hre.network.name !== 'hardhat'),
  },
  paths: {
    root: './',
    sources: './contracts',
    tests: './test',
    cache: './cache',
    artifacts: './artifacts',
  },
  mocha: {
    timeout: 20000,
  },
};

export default config;
