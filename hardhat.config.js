const dotenv = require("dotenv");
dotenv.config({ path: __dirname + "/.env" });

require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("@atixlabs/hardhat-time-n-mine");
require("hardhat-deploy");
require("hardhat-gas-reporter");
require("@openzeppelin/hardhat-upgrades");

const mnemonic = process.env.MNEMONIC;

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.6",
      },
    ],
  },

  gasReporter: {
    enabled: true,
  },

  networks: {
    development: {
      url: "http://127.0.0.1:8545", // Localhost (default: none)
      accounts: {
        mnemonic,
        count: 10,
      },
      live: false,
      saveDeployments: true,
    },
    avalanche: {
      url: process.env.AVALANCHE_MAINNET_PROVIDER,
      accounts: [process.env.PRIVATEKEY],
      gasPrice: 30000000000, // 30 nAVAX
      timeout: 900000,
      chainId: 43114,
    },
    avalanchetest: {
      url: process.env.AVALANCHE_TEST_PROVIDER,
      accounts: [process.env.PRIVATEKEY_TEST],
      gasPrice: 30000000000, // 30 nAVAX
      timeout: 900000,
      chainId: 43114,
    },
    mumbai: {
      url: process.env.MATIC_TESTNET_PROVIDER,
      accounts: [process.env.PRIVATEKEY_TEST],
      gasPrice: 30000000000, // 30 nMATIC
      timeout: 900000,
      chainId: 80001,
    },
    matic: {
      url: process.env.MATIC_MAINNET_PROVIDER,
      accounts: [process.env.PRIVATEKEY],
      gasPrice: 30000000000, // 30 nMATIC
      timeout: 900000,
      chainId: 137,
    },
    bsctest: {
      url: process.env.BSC_TESTNET_PROVIDER,
      accounts: [process.env.OWNER],
      timeout: 20000,
      gasPrice: 30000000000, // 30 nBNB
      chainId: 97,
    },
    bsc: {
      url: process.env.BSC_PROVIDER,
      accounts: [process.env.OWNER],
      timeout: 20000,
      gasPrice: 30000000000, // 30 nBNB
      chainId: 56,
    },
  },

  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./build/cache",
    artifacts: "./build/artifacts",
    deployments: "./deployments",
  },

  etherscan: {
    // apiKey: process.env.BSC_API_KEY,
    // apiKey: process.env.POLYGON_API_KEY,
    // apiKey: process.env.ETHERSCAN_API_KEY,
    // apiKey: process.env.FTMSCAN_API_KEY,
  },
};
