# Vault

A secure ETH deposit and withdrawal contract.

---

## What It Does

Users can deposit ETH into the vault and withdraw their own funds at any time. The owner can pause and unpause the contract in an emergency.

---

## Security Patterns Used

**Checks-Effects-Interactions (CEI)**

The single most important pattern for preventing reentrancy. Every function that sends ETH follows this strict order:

1. Checks -- validate all inputs and conditions
2. Effects -- update all state variables
3. Interactions -- make the external ETH transfer last

Without this order, an attacker could re-enter the withdraw function before the balance is zeroed and drain the contract repeatedly.

**Reentrancy Protection**

The balance is zeroed before the ETH transfer. A reentrant call finds a zero balance and is rejected at the checks stage.

**ETH Transfer via call()**

Uses call() instead of transfer() or send(). transfer() and send() forward only 2300 gas which fails for contract recipients with complex fallback functions. call() forwards all gas and returns a success boolean which is explicitly checked.

**Custom Errors**

Uses custom errors instead of require() strings. More gas efficient and easier to handle programmatically.

**Pause Mechanism**

Owner can halt deposits and withdrawals in an emergency without touching funds.

---

## What Would Happen Without These Patterns

If state were updated after the ETH transfer, an attacker deploying a malicious contract with a reentrant receive() function could drain the entire vault in a single transaction. This exact vulnerability caused the 2016 DAO hack -- approximately 60 million USD lost.

---

## Functions

| Function | Access | Description |
|----------|--------|-------------|
| deposit() | Public | Deposit ETH into the vault |
| withdraw(amount) | Public | Withdraw your own ETH |
| pause() | Owner only | Halt all deposits and withdrawals |
| unpause() | Owner only | Resume normal operation |
| getBalance() | Public | View your own balance |
| getTotalBalance() | Public | View total ETH held by the contract |

---

## Tools

- Solidity 0.8.20
- Foundry tests -- coming soon
- Slither analysis -- coming soon
