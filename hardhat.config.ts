import '@nomiclabs/hardhat-etherscan'
import '@nomiclabs/hardhat-waffle'
import '@nomiclabs/hardhat-web3'
import '@openzeppelin/hardhat-upgrades'
import '@typechain/hardhat'
import 'hardhat-gas-reporter'

import * as dotenv from 'dotenv'
import { HardhatUserConfig, task } from 'hardhat/config'

import exportAllowlistMintCSV from './tasks/exportAllowlistMintCSV'
import exportHashedAllowlistJsonTask from './tasks/exportHashedAllowlistJsonTask'
import snapshotTask from './tasks/snapshotTask'

dotenv.config()

task("accounts")
  .setDescription("Prints the list of accounts")
  .setAction(async (args, env) => {
    const accounts = await env.ethers.getSigners()
    for (const account of accounts) console.log(account.address)
  })

task("snapshot")
  .setDescription("Take a snapshot of owners of a collection")
  .setAction(snapshotTask)

task("exportAllowlist")
  .setDescription("Export hashed-allowlist addresses to a JSON file")
  .setAction(exportHashedAllowlistJsonTask)


task("exportAllowlistMintProgress")
  .setDescription("Export allowlist minting progress to a CSV")
  .setAction(exportAllowlistMintCSV)

const accounts = [
  process.env.DEPROY_WALLET_PRIVATE_KEY,
].filter((elm?: string): elm is string => elm !== undefined)

const testAccounts = [
  process.env.TEST_WALLET_PRIVATE_KEY,
].filter((elm?: string): elm is string => elm !== undefined)

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      }
    }
  },
  networks: {
    hardhat: {
      chainId: 1337,
    },
    // Ethereum networks
    mainnet: {
      url: process.env.MAINNET_URL || "",
      chainId: 1,
      accounts: accounts,
    },
    goerli: {
      url: process.env.GOERLI_URL || "",
      chainId: 5,
      accounts: testAccounts,
    },
    // Binance smart chains
    bsc_mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      accounts: accounts,
    },
    bsc_testnet: {
      url: "https://data-seed-prebsc-2-s3.binance.org:8545/",
      chainId: 97,
      accounts: testAccounts,
    },
  },
  gasReporter: {
    enabled: true,
    currency: "JPY",
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
    // apiKey: process.env.BSCSCAN_API_KEY,
  },
}

export default config
