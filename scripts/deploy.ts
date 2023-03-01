import { parseEther } from 'ethers/lib/utils'
import env, { ethers, upgrades } from 'hardhat'

import { LatestBNG, latestBNGFactory } from '../libraries/const'
import HardhatRuntimeUtility from '../libraries/HardhatRuntimeUtility'

async function main() {
  const util = new HardhatRuntimeUtility(env)
  if (await util.isProxiesDeployed(1)) throw Error("Proxy has already been deployed! 'Upgrade' instead.")

  const instance = await upgrades.deployProxy(await latestBNGFactory) as LatestBNG
  await instance.deployed()

  console.log(await instance.name(), " is deployed to: ", instance.address)

  const [deployer] = await ethers.getSigners()
  let nonce = await ethers.provider.getTransactionCount(deployer.address)

  // set variables
  await instance.setMintLimit(1000, { nonce: nonce++ })
  // public mint
  if (!await instance.isPublicMintPaused()) await instance.pausePublicMint({ nonce: nonce++ })
  await instance.setPublicPrice(parseEther("0.0001"), { nonce: nonce++ })
  // allowlist mint
  if (!await instance.isAllowlistMintPaused()) await instance.pauseAllowlistMint({ nonce: nonce++ })
  await instance.setAllowListPrice(parseEther("0.0001"), { nonce: nonce++ })
  await instance.setAllowlistedMemberMintLimit(3, { nonce: nonce++ })
  // royalty
  await instance.setRoyaltyFraction(500, { nonce: nonce++ }) // 5%
  await instance.setRoyaltyReceiver(deployer.address, { nonce: nonce++ })
  // withdrawal
  await instance.setWithdrawalReceiver(deployer.address, { nonce: nonce++ })
}

main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
