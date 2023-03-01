import { expect } from 'chai'
import { ethers, upgrades } from 'hardhat'
import { describe } from 'mocha'

import { LatestBNG, latestBNGFactory } from '../libraries/const'

describe("Withdraw from BNG", () => {
    it("Withdraw all", async () => {
        const [deployer] = await ethers.getSigners()

        const factory = await latestBNGFactory
        const instance = await upgrades.deployProxy(factory) as LatestBNG

        if (await instance.isPublicMintPaused()) await instance.unpausePublicMint()
        await instance.setMintLimit(200)

        const mintPrice = await instance.publicPrice()
        const paid = mintPrice.mul(100)

        const balanceBeforePay = await deployer.getBalance()
        await instance.publicMint(100, { value: paid })
        const balanceAfterPay = await deployer.getBalance()

        expect(await instance.provider.getBalance(instance.address)).to.equal(paid)
        expect(balanceBeforePay.sub(balanceAfterPay).gt(paid)).is.true // gt because of gas

        await instance.withdraw()
        const balanceAfterWithdraw = await deployer.getBalance()

        expect(await instance.provider.getBalance(instance.address)).to.equal(0)
        expect(balanceAfterWithdraw.gt(balanceAfterPay))
        expect(balanceAfterWithdraw.lt(balanceBeforePay)) // lt because of gas
    })

    it("Nobody can withdraw other than owner", async () => {
        const [, badguy] = await ethers.getSigners()

        const factory = await latestBNGFactory
        const instance = await upgrades.deployProxy(factory) as LatestBNG

        await instance.withdraw() // ok
        await expect(instance.connect(badguy).withdraw()).to.revertedWith("Ownable: caller is not the owner")
    })

    it("Withdrawal receiver receives all", async () => {
        const [, alice, , , , , , , ivan] = await ethers.getSigners()

        const factory = await latestBNGFactory
        const instance = await upgrades.deployProxy(factory) as LatestBNG

        if (await instance.isPublicMintPaused()) await instance.unpausePublicMint()
        await instance.setMintLimit(200)

        const mintPrice = await instance.publicPrice()
        const paid = mintPrice.mul(100)
        await expect(await instance.connect(alice).publicMint(100, { value: paid }))
            .to.changeEtherBalances([instance, alice], [paid, paid.mul(-1)])


        await instance.setWithdrawalReceiver(ivan.address)
        await expect(await instance.withdraw())
            .to.changeEtherBalances([instance, ivan], [paid.mul(-1), paid])

    })
})