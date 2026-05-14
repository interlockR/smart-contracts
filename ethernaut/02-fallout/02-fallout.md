# Ethernaut Level 02 -- Fallout

**Game:** Ethernaut by OpenZeppelin
**Level:** 02 -- Fallout
**Category:** Access Control / Constructor Naming Bug
**Network:** Sepolia Testnet
**Status:** Completed

---

## Objective

Claim ownership of the contract.

---

## The Vulnerability

In Solidity versions before 0.8.0, constructors were defined as functions with the same name as the contract. If the function name did not match the contract name exactly, it was not treated as a constructor -- it became a regular public function callable by anyone.

The contract is named Fallout. The supposed constructor is named Fal1out -- with the number 1 in place of the letter l. This single character difference means the function is never executed as a constructor at deployment. Instead it sits as a public function with no access control that sets owner = msg.sender when called.

    /* constructor */
    function Fal1out() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }

Anyone who calls Fal1out() becomes the owner.

---

## Attack Steps

Step 1 -- Call the misnamed constructor function directly:

    await contract.Fal1out()

Step 2 -- Verify ownership transferred:

    await contract.owner()
    // returns player address

---

## The Fix

Solidity 0.8.0 introduced the constructor keyword, making this class of bug impossible. Constructors are now defined explicitly:

    constructor() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }

There is no function name to misspell. The compiler handles constructor identification, not the developer.

For contracts still using older Solidity versions, the fix is to ensure the constructor function name matches the contract name exactly -- character for character, including case. A mismatch of any kind turns the constructor into a public function.

---

## Real World Impact

This exact bug was found in the Rubixi smart contract in 2016. The contract was originally named DynamicPyramid but was renamed to Rubixi before deployment. The constructor function name was never updated to match, leaving the original DynamicPyramid() function as a publicly callable ownership transfer. Attackers used it to claim ownership and drain funds from the contract.

---

## Key Takeaway

Constructor naming bugs are a Solidity-specific vulnerability class that no longer exists in modern Solidity but is still present in a large number of deployed contracts written before 0.8.0. When auditing older contracts, always verify that the supposed constructor is actually being treated as one. A constructor that is really a public function is one of the most critical vulnerabilities possible -- it hands ownership to anyone who finds it.

---

## References

- Ethernaut Level 02 -- https://ethernaut.openzeppelin.com/level/2
- Solidity Documentation -- Constructors
- SWC-118 -- Incorrect Constructor Name
- Rubixi incident -- 2016
