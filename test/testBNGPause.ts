import { expect } from 'chai'
import { BigNumber } from 'ethers'
import { keccak256 } from 'ethers/lib/utils'
import { ethers, upgrades } from 'hardhat'
import MerkleTree from 'merkletreejs'
import { describe, it } from 'mocha'

import { LatestBNG, latestBNGFactory } from '../libraries/const'

describe("Pause BNG", () => {
    it("Toggle allowlist mint pausing", async () => {
        const factory = await latestBNGFactory
        const instance = await upgrades.deployProxy(factory) as LatestBNG

        // unpause if it's paused
        if (await instance.isAllowlistMintPaused())
            await instance.unpauseAllowlistMint()

        await expect(instance.pauseAllowlistMint())
            .to.emit(instance, "AllowlistMintPaused")

        expect(await instance.isAllowlistMintPaused()).is.true

        await expect(instance.pauseAllowlistMint())
            .to.revertedWith("allowlist mint: paused")

        await expect(instance.unpauseAllowlistMint())
            .to.emit(instance, "AllowlistMintUnpaused")

        expect(await instance.isAllowlistMintPaused()).is.false

        await expect(instance.unpauseAllowlistMint())
            .to.revertedWith("allowlist mint: not paused")
    })


    it("Toggle public mint pausing", async () => {
        const factory = await latestBNGFactory
        const instance = await upgrades.deployProxy(factory) as LatestBNG

        // unpause if it's paused
        if (await instance.isPublicMintPaused())
            await instance.unpausePublicMint()

        await expect(instance.pausePublicMint())
            .to.emit(instance, "PublicMintPaused")

        expect(await instance.isPublicMintPaused()).is.true

        await expect(instance.pausePublicMint())
            .to.revertedWith("public mint: paused")

        await expect(instance.unpausePublicMint())
            .to.emit(instance, "PublicMintUnpaused")

        expect(await instance.isPublicMintPaused()).is.false

        await expect(instance.unpausePublicMint())
            .to.revertedWith("public mint: not paused")
    })

    it("Allowlist mint is not available if it's paused", async () => {
        const factory = await latestBNGFactory
        const instance = await upgrades.deployProxy(factory) as LatestBNG
        const [, john, jonny, jonathan] = await ethers.getSigners()

        if (!(await instance.isAllowlistMintPaused())) await instance.pauseAllowlistMint()

        // register allowlist
        const allowlisted = [john, jonny, jonathan]
        const leaves = allowlisted.map(account => keccak256(account.address))
        const tree = new MerkleTree(leaves, keccak256, { sort: true })
        const root = tree.getHexRoot()
        await instance.setAllowlist(root)

        // check balance to mint
        const price: BigNumber = await instance.allowListPrice()
        const quantity: BigNumber = await instance.allowlistedMemberMintLimit()
        const totalPrice = price.mul(quantity)
        const balance = await jonathan.getBalance()
        expect(balance.gte(totalPrice)).is.true

        const proofOfJonathan = tree.getHexProof(keccak256(jonathan.address))
        await expect(instance.connect(jonathan).allowlistMint(quantity, proofOfJonathan, { value: totalPrice })).to.revertedWith("allowlist mint: paused")
    })
})