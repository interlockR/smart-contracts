# Token

A mintable ERC-20 token implemented from scratch with owner-only minting and a fixed maximum supply.

---

## What It Does

Implements the ERC-20 standard manually without inheriting from OpenZeppelin. The owner can mint new tokens up to a hard cap set at deployment. Standard transfer, approve, and transferFrom functions are included.

---

## Security Patterns Used

**Access Control**

Only the owner can mint tokens. Without this, anyone could inflate the supply and devalue existing holders. The owner address is set as immutable at deployment -- it cannot be changed or transferred.

**Maximum Supply Cap**

A hard cap is enforced on every mint call. Even the owner cannot mint beyond the limit set at deployment. The cap is stored as immutable.

**Zero Address Checks**

All functions that move tokens check that the recipient is not address(0). Sending tokens to address(0) permanently destroys them with no way to recover.

**Overflow and Underflow Protection**

Solidity 0.8.x has built-in arithmetic checks that revert automatically on overflow or underflow. In versions before 0.8.x this had to be handled manually with SafeMath -- without it, an attacker could wrap a uint256 around zero to give themselves a massive balance.

**Approval Race Condition -- Documented**

The ERC-20 approve() function has a known race condition. If Alice approves Bob for 100 tokens and then changes it to 50, Bob can front-run the second transaction and spend 150 total. This is documented in the contract. The mitigation is to set allowance to 0 first before setting the new value.

---

## Functions

| Function | Access | Description |
|----------|--------|-------------|
| mint(to, amount) | Owner only | Mint new tokens up to the supply cap |
| transfer(to, amount) | Public | Transfer tokens to another address |
| approve(spender, amount) | Public | Approve a spender to use your tokens |
| transferFrom(from, to, amount) | Public | Transfer on behalf of another address |
| balanceOf(account) | Public | View token balance of an address |
| allowance(owner, spender) | Public | View approved spending amount |

---

## Tools

- Solidity 0.8.20
- Foundry tests -- coming soon
- Slither analysis -- coming soon
