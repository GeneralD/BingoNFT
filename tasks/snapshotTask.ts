import { HardhatRuntimeEnvironment } from 'hardhat/types'
import ObjectsToCsv from 'objects-to-csv'
import { join } from 'path'

import {
    getNftsForOwner, getOwnersForCollection, initializeAlchemy, Network, OwnedNft
} from '@alch/alchemy-sdk'

export default async (arg: any, env: HardhatRuntimeEnvironment) => {
    const alchemy = initializeAlchemy({
        apiKey: process.env.MAINNET_KEY,
        network: Network.ETH_MAINNET,
        maxRetries: 3,
    })

    // Airdrops are supplied to owners of this NFT
    const contractAddress = "0x1111111111222222222233333333334444444444"

    const ownersResponse = await getOwnersForCollection(alchemy, contractAddress)
    // filter to exclude burnt (zero address)
    const owners = ownersResponse.owners.filter(owner => owner !== "0x0000000000000000000000000000000000000000")

    const rows: { address: string, balance: number }[] = []
    for (const owner of owners) {
        async function ownedNfts(pageKey: string | undefined = undefined) {
            const response = await getNftsForOwner(alchemy, owner, { contractAddresses: [contractAddress], pageKey })
            if (!response.pageKey) return response.ownedNfts
            const next: OwnedNft[] = await ownedNfts(response.pageKey)
            return response.ownedNfts.concat(next)
        }
        const nfts = await ownedNfts()
        rows.push({ address: owner, balance: nfts.length, })
    }

    const csv = new ObjectsToCsv(rows)
    csv.toDisk(join(__dirname, "holders.csv"))
}
