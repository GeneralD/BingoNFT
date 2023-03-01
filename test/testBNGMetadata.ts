import { expect, use } from 'chai'
import chaiArrays from 'chai-arrays'
import chaiString from 'chai-string'
import { upgrades } from 'hardhat'
import { describe } from 'mocha'

import { LatestBNG, latestBNGFactory } from '../libraries/const'

use(chaiArrays)
use(chaiString)

describe("Mint BNG as allowlisted member", () => {
    it("Allowlisted member can mint", async () => {
        const factory = await latestBNGFactory
        const instance = await upgrades.deployProxy(factory) as LatestBNG

        await instance.setMintLimit(100)
        await instance.adminMint(1)

        const uri = await instance.tokenURI(1)

        expect(uri).startsWith("data:application/json;base64,")
        var json = JSON.parse(atob(uri.replace("data:application/json;base64,", "")))

        expect(json.image).startsWith("data:image/svg+xml;base64,")
        const svg = atob(json.image.replace("data:image/svg+xml;base64,", ""))

        expect(svg).startsWith('<svg')

        expect(json.matrix).to.be.equalTo([4, 14, 9, 11, 10, 25, 20, 29, 22, 27, 43, 38, 0, 40, 45, 52, 54, 46, 56, 60, 68, 73, 74, 65, 64])
    })
})