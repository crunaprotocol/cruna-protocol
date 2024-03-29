const {requirePath} = require("require-or-mock");
// if missing, it sets up a mock
requirePath(".env");
requirePath("export/deployed.json");

require("dotenv").config();
require("@secrez/cryptoenv").parse(() => process.env.NODE_ENV !== "test" && !process.env.SKIP_CRYPTOENV);

const {env} = process;

process.on('warning', (warning) => {
  console.log(warning.stack);
});

require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("@openzeppelin/hardhat-upgrades");
require("hardhat-contract-sizer");
require("solidity-coverage");
require('solidity-docgen');

if (process.env.GAS_REPORT === "yes") {
  require("hardhat-gas-reporter");
}

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.22",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      }
      // viaIR: true,
      // optimizer: {
      //   enabled: true,
      //   details: {
      //     yulDetails: {
      //       optimizerSteps: "u",
      //     },
      //   },
      // },
    },
  },
  networks: {
    hardhat: {
      blockGasLimit: 10000000,
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 1337,
    },
    ethereum: {
      url: `https://mainnet.infura.io/v3/${env.INFURA_API_KEY}`,
      accounts: [env.DEPLOYER],
      chainId: 1,
    },
    bsc: {
      url: "https://bsc-dataseed.binance.org",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: [env.DEPLOYER],
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${env.INFURA_API_KEY}`,
      gasLimit: 6000000,
      accounts: [env.DEPLOYER],
    },
    bsc_testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      // gasPrice: 20000000000,
      gasLimit: 6000000,
      accounts: [env.DEPLOYER],
    },
    mumbai: {
      // url: "https://rpc-mumbai.maticvigil.com",
      url: "https://polygon-mumbai.blockpi.network/v1/rpc/public",
      chainId: 80001,
      // gasPrice: 20000000000,
      gasLimit: 6000000,
      accounts: [env.DEPLOYER],
    },
    fuji: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      gasPrice: 225000000000,
      chainId: 43113,
      accounts: [env.DEPLOYER],
    },
    avalance: {
      url: "https://api.avax.network/ext/bc/C/rpc",
      gasPrice: 225000000000,
      chainId: 43114,
      accounts: [env.DEPLOYER],
    },
    alfajores: {
      url: "https://alfajores-forno.celo-testnet.org",
      accounts: [env.DEPLOYER],
      chainId: 44787,
    },
  },
  etherscan: {
    // apiKey: env.BSCSCAN_KEY,
  },
  gasReporter: {
    currency: "USD",
    // coinmarketcap: env.coinMarketCapAPIKey
  },
  docgen: {
    exclude: ["mocks"],
    pages: "files"
  }
};
