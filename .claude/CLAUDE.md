# BingoNFT

Upgradeable ERC721A NFT smart contract ("Bingo NFT", symbol BNG) with Merkle-proof
allowlist minting, public minting, burning, EIP-2981 royalties, pause switches, and
withdrawal — built on a Hardhat + TypeScript project template for the author's
"Cannon" NFT tooling.

- Language/stack: Solidity 0.8.18 (optimizer on), Hardhat 2.x, TypeScript 4.x,
  ethers v5 + waffle + typechain, OpenZeppelin upgradeable + erc721a-upgradeable.
- Status: legacy project (last commit 2023-03); dependencies are dated. UNLICENSED.
- Networks configured: Ethereum mainnet/goerli, BSC mainnet/testnet (env-driven keys).

Key directories:

- `contracts/BNGVer0.sol` — the single contract (all logic).
- `scripts/` — deploy / upgrade / mint / airdrop / updateAllowlist (hardhat run).
- `tasks/` — custom hardhat tasks: snapshot, exportAllowlist, exportAllowlistMintProgress.
- `libraries/` — merkle root creation, constants, hardhat runtime helpers.
- `test/` — per-feature mocha tests (admin mint, allowlist, burn, royalty, etc.).

Build/run: `yarn install` then `npx hardhat compile` / `npx hardhat test`
(old toolchain — Node version pinned in `.node-version`; not re-verified recently).
