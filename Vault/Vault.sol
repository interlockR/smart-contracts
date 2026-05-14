// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Vault
 * @author Vektasafe
 * @notice A secure ETH vault allowing users to deposit and withdraw their own funds.
 *
 * Security considerations documented inline throughout this contract.
 * This contract is a learning artefact and is not intended for production use.
 */
contract Vault {

    // -------------------------------------------------------------------------
    // State variables
    // -------------------------------------------------------------------------

    /// @notice Tracks each user's deposited ETH balance.
    /// @dev Using a mapping rather than a single balance prevents one user
    ///      from withdrawing another user's funds.
    mapping(address => uint256) private balances;

    /// @notice The owner of the contract — set once at deployment, never changed.
    address public immutable owner;

    /// @notice Tracks whether the contract is paused.
    /// @dev In an emergency, the owner can pause all withdrawals and deposits.
    bool public paused;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @dev Emitting events on every state change creates an on-chain audit trail.
    ///      This is important for transparency and off-chain monitoring.
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Paused(address indexed by);
    event Unpaused(address indexed by);

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @dev Custom errors (introduced in Solidity 0.8.4) are more gas-efficient
    ///      than revert strings and provide structured error data for off-chain tooling.
    error ZeroAmount();
    error InsufficientBalance(uint256 requested, uint256 available);
    error NotOwner();
    error ContractPaused();
    error TransferFailed();

    // -------------------------------------------------------------------------
    // Modifiers
    // -------------------------------------------------------------------------

    /// @dev Restricts a function to the contract owner only.
    ///      SECURITY: Without access control, anyone could pause or unpause the vault.
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @dev Prevents function execution when the contract is paused.
    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /// @dev The owner is set once at deployment using msg.sender.
    ///      Using `immutable` means the owner value is baked into the bytecode
    ///      and cannot be changed after deployment — no setter needed.
    constructor() {
        owner = msg.sender;
    }

    // -------------------------------------------------------------------------
    // External functions
    // -------------------------------------------------------------------------

    /**
     * @notice Deposit ETH into the vault.
     * @dev msg.value is the ETH sent with this transaction.
     *      SECURITY: We check for zero deposits to avoid polluting event logs
     *      and wasting gas on meaningless state changes.
     */
    function deposit() external payable whenNotPaused {
        if (msg.value == 0) revert ZeroAmount();

        // PATTERN: Checks-Effects-Interactions
        // We update state (effect) BEFORE any external interaction.
        // Here there is no external call, but establishing the habit is critical.
        balances[msg.sender] += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw a specified amount of ETH from the vault.
     * @param amount The amount in wei to withdraw.
     *
     * @dev SECURITY - Reentrancy protection via Checks-Effects-Interactions (CEI):
     *
     *      A reentrancy attack occurs when an external contract calls back into
     *      this function before the first execution completes. If we sent ETH
     *      BEFORE updating balances, the attacker could re-enter and drain funds.
     *
     *      The correct order is always:
     *        1. CHECKS   -- validate inputs and state
     *        2. EFFECTS  -- update state variables
     *        3. INTERACTIONS -- make external calls (ETH transfer)
     *
     *      By zeroing the balance BEFORE the transfer, a reentrant call
     *      would find a zero balance and be rejected at the CHECKS stage.
     */
    function withdraw(uint256 amount) external whenNotPaused {
        // CHECKS
        if (amount == 0) revert ZeroAmount();
        uint256 userBalance = balances[msg.sender];
        if (amount > userBalance) revert InsufficientBalance(amount, userBalance);

        // EFFECTS -- update state before any external call
        balances[msg.sender] = userBalance - amount;

        // INTERACTIONS -- external ETH transfer happens last
        // SECURITY: Using call() instead of transfer() or send().
        //   transfer() and send() forward only 2300 gas, which can fail if the
        //   recipient is a contract with a complex fallback function.
        //   call() forwards all available gas but requires explicit success checking.
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed();

        emit Withdrawn(msg.sender, amount);
    }

    // -------------------------------------------------------------------------
    // Owner functions
    // -------------------------------------------------------------------------

    /// @notice Pause all deposits and withdrawals.
    /// @dev SECURITY: A pause mechanism allows the owner to freeze the contract
    ///      in the event of a detected exploit or vulnerability disclosure.
    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpause the contract.
    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // -------------------------------------------------------------------------
    // View functions
    // -------------------------------------------------------------------------

    /// @notice Returns the caller's current deposited balance.
    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    /// @notice Returns the total ETH held by this contract.
    function getTotalBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // -------------------------------------------------------------------------
    // Fallback and receive
    // -------------------------------------------------------------------------

    /// @dev receive() handles plain ETH transfers sent to this contract address.
    ///      We credit the sender's balance so funds are not silently locked.
    receive() external payable {
        if (msg.value > 0) {
            balances[msg.sender] += msg.value;
            emit Deposited(msg.sender, msg.value);
        }
    }
}
