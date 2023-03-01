import env, { ethers } from 'hardhat'

import { LatestBNG, latestBNGFactory } from '../libraries/const'
import HardhatRuntimeUtility from '../libraries/HardhatRuntimeUtility'

async function main() {
    const util = new HardhatRuntimeUtility(env)
    const factory = await latestBNGFactory
    const instance = factory.attach((await util.deployedProxies(1))[0].address) as LatestBNG

    const [deployer] = await ethers.getSigners()
    let nonce = await ethers.provider.getTransactionCount(deployer.address)

    await instance.setMintLimit(10000, { nonce: nonce++ })
    await instance.adminMint(20)
}

main().catch(error => {
    console.error(error)
    process.exitCode = 1
})
