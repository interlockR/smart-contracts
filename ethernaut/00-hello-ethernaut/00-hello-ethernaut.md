# Ethernaut Level 00 -- Hello Ethernaut

**Game:** Ethernaut by OpenZeppelin
**Level:** 00 -- Hello Ethernaut
**Category:** Blockchain Basics / Information Disclosure
**Network:** Sepolia Testnet
**Status:** Completed

---

## Objective

Authenticate with the contract by finding the correct password.

---

## Process

The level presents a contract with no obvious entry point. The only instruction is to call contract.info() and follow where it leads.

Working through the chain of method calls:

await contract.info()
// "You will find what you need in info1()."

await contract.info1()
// "Try info2(), but with 'hello' as a parameter."

await contract.info2("hello")
// "The property infoNum holds the number of the next info method to call."

await contract.infoNum()
// 42

await contract.info42()
// "theMethodName is the name of the next method."

await contract.theMethodName()
// "The method name is method7123949."

await contract.method7123949()
// "If you know the password, submit it to authenticate()."

await contract.password()
// "ethernaut0"

await contract.authenticate("ethernaut0")
// Transaction confirmed -- level cleared.

---

## The Vulnerability

The password was stored as a public state variable:

    string public password;

The public keyword automatically generates a getter function, making the password directly readable by anyone through a simple contract call. This is what allowed contract.password() to return the plaintext password with no restrictions.

---

## The Deeper Issue

Even if the variable had been marked private, the password would still be recoverable. In Solidity, private only restricts access from other smart contracts. It does not hide data from anyone interacting with the blockchain directly.

Every state variable in a smart contract is stored in the contract's storage slots on the blockchain. These slots are publicly readable by anyone using standard RPC calls, regardless of the visibility modifier in the Solidity code.

The distinction matters:

- public -- any contract or external caller can read the value through the generated getter
- private -- other contracts cannot call a getter, but the raw storage slot is still publicly readable on-chain

Neither provides confidentiality for sensitive data.

---

## The Fix

Sensitive values such as passwords, private keys, or access codes should never be stored on-chain in any form. If authentication is required, the correct pattern is to store a hash of the secret and compare submitted values against the hash:

    bytes32 private passwordHash;

    constructor(string memory _password) {
        passwordHash = keccak256(abi.encodePacked(_password));
    }

    function authenticate(string memory passkey) public {
        if (keccak256(abi.encodePacked(passkey)) == passwordHash) {
            cleared = true;
        }
    }

This way the plaintext password is never stored on-chain. An attacker reading the storage slot gets only the hash, which cannot be reversed to recover the original password unless it is weak enough to brute force.

Even then, truly sensitive access control should not rely on a shared secret at all. Better patterns include signature verification, role-based access control via OpenZeppelin's AccessControl, or multi-sig schemes depending on the use case.

---

## Key Takeaway

There is no private data on a public blockchain. Everything stored in contract state is readable by anyone with access to an RPC node. Smart contract security cannot rely on obscurity or access modifiers for confidentiality. If data must be kept secret, it must stay off-chain.

---

## References

- Ethernaut Level 00 -- https://ethernaut.openzeppelin.com/level/0
- Solidity Documentation -- State Variable Visibility
- SWC-136 -- Unencrypted Private Data On-Chain
