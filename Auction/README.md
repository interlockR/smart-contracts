# Auction

A timed ETH auction where the highest bidder wins and all losing bidders can withdraw their funds.

---

## What It Does

The seller deploys the contract with a duration and item description. Bidders compete by sending ETH. Each new bid must exceed the current highest. When time expires anyone can call finalise() to send the winning bid to the seller. All losing bidders withdraw their own refunds.

---

## Security Patterns Used

**Pull-over-Push Refund Pattern**

Refunds are not sent automatically when a bidder is outbid. Instead they are stored in a pendingRefunds mapping. Each losing bidder calls withdraw() themselves to claim their refund.

Why this matters: if the contract pushed ETH to the previous bidder mid-execution, a malicious bidder could deploy a contract whose receive() function always reverts. This would permanently block all new bids -- a denial of service attack. The pull pattern means no single participant can block the contract.

**Checks-Effects-Interactions (CEI)**

The withdraw() function zeros the refund balance before sending ETH. A reentrant call finds a zero balance and is rejected. Without this order an attacker could drain all pending refunds in a single transaction.

**Double Finalisation Guard**

The ended boolean prevents the seller from calling finalise() twice and receiving double payment.

**Timestamp Dependence -- Documented**

block.timestamp can be manipulated by block producers by approximately 15 seconds. For auctions measured in hours or days this is not a meaningful risk. For very short auctions or high-value edge cases it becomes a consideration worth noting.

---

## Functions

| Function | Access | Description |
|----------|--------|-------------|
| bid() | Public payable | Place a bid higher than the current highest |
| withdraw() | Public | Claim your refund after being outbid |
| finalise() | Public | End the auction and pay the seller |
| getPendingRefund(address) | Public | View pending refund for any address |
| timeRemaining() | Public | View seconds left in the auction |

---

## Tools

- Solidity 0.8.20
- Foundry tests -- coming soon
- Slither analysis -- coming soon
