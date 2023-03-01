import { ethers } from 'hardhat'

import { BNGVer0 } from '../typechain'

export const latestBNGFactory = ethers.getContractFactory("BNGVer0")
export type LatestBNG = BNGVer0
