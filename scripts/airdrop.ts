import csv from 'csv-parser'
import { createReadStream } from 'fs'
import env, { ethers } from 'hardhat'
import { join } from 'path'

import { latestBNGFactory } from '../libraries/const'
import HardhatRuntimeUtility from '../libraries/HardhatRuntimeUtility'

async function main() {
    const util = new HardhatRuntimeUtility(env)
    const factory = await latestBNGFactory
    const instance = factory.attach((await util.deployedProxies(1))[0].address)
    await instance.deployed()

    const rows: { address: string, balance: number }[] = []
    createReadStream(join(__dirname, "holders.csv"))
        .pipe(csv())
        .on("data", data => rows.push(data))
        .on("error", err => console.error(err.message))
        .on("end", () => console.log(`Start airdrop to ${rows.length} addresses.`))

    const [deployer] = await ethers.getSigners()
    let nonce = await ethers.provider.getTransactionCount(deployer.address)

    for (const row of rows) {
        await instance.adminMintTo(row.address, row.balance, { nonce: nonce++ })
    }
}

main().catch(error => {
    console.error(error)
    process.exitCode = 1
})
