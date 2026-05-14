# Smart Contracts

Documented Solidity smart contracts built as part of a focused path toward professional smart contract auditing. Each contract is a standalone piece of work with its own security breakdown.

---

## Contracts

| # | Contract | Description | Security Focus |
|---|----------|-------------|----------------|
| 1 | [Vault](./Vault/) | Secure ETH deposit and withdrawal | Reentrancy, CEI pattern, access control |
| 2 | [Token](./Token/) | Mintable ERC-20 with supply cap | Access control, overflow, zero address |
| 3 | [Auction](./Auction/) | Timed ETH auction with refunds | Pull-over-push, denial of service, CEI |

---

## Structure

Each contract lives in its own folder containing the Solidity file and a dedicated README covering what the contract does, the security patterns used, and what would happen without those patterns.

---

## Status

- [x] Vault
- [x] Token
- [x] Auction
- [ ] Foundry tests
- [ ] Slither static analysis
- [ ] Formal audit reports

---

## Purpose

These contracts are learning artefacts built to develop and demonstrate understanding of Solidity patterns, common vulnerability classes, and secure contract design. Part of the Vektasafe Web3 security portfolio at github.com/vektasafe-dev.

---

## Ethernaut CTF Writeups

| # | Level | Category | Status |
|---|-------|----------|--------|
| 00 | [Hello Ethernaut](./ethernaut/00-hello-ethernaut.md) | Information Disclosure | Completed |
| 01 | [Fallback](./ethernaut/01-fallback.md) | Access Control / Ownership Hijack | Completed |
| 02 | [Fallout](./ethernaut/02-fallout.md) | Access Control / Constructor Naming Bug | Completed |
| 03 | [CoinFlip](./ethernaut/03-coinflip.md) | Weak Randomness / Predictable On-Chain Values | Completed |
| 04 | [Telephone](./ethernaut/04-telephone.md) | Access Control / tx.origin Misuse | Completed |
