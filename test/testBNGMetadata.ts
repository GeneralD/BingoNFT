import { expect, use } from 'chai'
import chaiString from 'chai-string'
import { upgrades } from 'hardhat'
import { describe } from 'mocha'

import { LatestBNG, latestBNGFactory } from '../libraries/const'

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

        console.log(svg)

        // expect(svg).to.equals("tast")
    })
})