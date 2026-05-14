// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Token
 * @author Vektasafe
 * @notice A mintable ERC-20 token with owner-only minting and a fixed maximum supply.
 *
 * Implements the ERC-20 standard manually (without OpenZeppelin) for learning purposes.
 * Security considerations documented inline throughout this contract.
 * This contract is a learning artefact and is not intended for production use.
 */
contract Token {

    // -------------------------------------------------------------------------
    // State variables
    // -------------------------------------------------------------------------

    /// @notice Human-readable name of the token.
    string public name;

    /// @notice Ticker symbol of the token.
    string public symbol;

    /// @notice Number of decimal places. 18 is the ERC-20 standard.
    /// @dev 1 token = 1 * 10**18 base units (similar to 1 ETH = 10**18 wei).
    uint8 public constant decimals = 18;

    /// @notice Maximum tokens that can ever exist.
    /// @dev SECURITY: Without a supply cap, an owner could mint unlimited tokens,
    ///      destroying the token's value. The cap is enforced in the mint function.
    uint256 public immutable maxSupply;

    /// @notice Current total supply of minted tokens.
    uint256 public totalSupply;

    /// @notice The contract owner — the only address permitted to mint tokens.
    address public immutable owner;

    /// @dev Maps each address to its token balance.
    mapping(address => uint256) private _balances;

    /// @dev Maps owner => spender => approved amount.
    ///      SECURITY: The allowance system prevents a spender from taking more
    ///      than the owner explicitly approved.
    mapping(address => mapping(address => uint256)) private _allowances;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @dev ERC-20 standard requires these two events to be emitted.
    ///      External tools (block explorers, wallets) rely on these events
    ///      to track token movements without reading contract storage directly.
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Minted(address indexed to, uint256 amount);

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    error NotOwner();
    error ZeroAddress();
    error ZeroAmount();
    error InsufficientBalance(uint256 requested, uint256 available);
    error InsufficientAllowance(uint256 requested, uint256 available);
    error MaxSupplyExceeded(uint256 requested, uint256 remaining);

    // -------------------------------------------------------------------------
    // Modifiers
    // -------------------------------------------------------------------------

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @dev SECURITY: Many token exploits involve zero-address transfers that
    ///      permanently burn tokens by sending them to address(0).
    ///      Checking for the zero address prevents accidental token loss.
    modifier validAddress(address addr) {
        if (addr == address(0)) revert ZeroAddress();
        _;
    }

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /**
     * @param _name Token name (e.g. "Vektasafe Token")
     * @param _symbol Token symbol (e.g. "ILK")
     * @param _maxSupply Maximum supply in full tokens (will be scaled by 10**18 internally)
     */
    constructor(string memory _name, string memory _symbol, uint256 _maxSupply) {
        name = _name;
        symbol = _symbol;
        // Scale maxSupply to include decimals
        maxSupply = _maxSupply * (10 ** decimals);
        owner = msg.sender;
    }

    // -------------------------------------------------------------------------
    // ERC-20 standard functions
    // -------------------------------------------------------------------------

    /// @notice Returns the token balance of an address.
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /// @notice Returns the remaining allowance a spender has from an owner.
    function allowance(address tokenOwner, address spender) external view returns (uint256) {
        return _allowances[tokenOwner][spender];
    }

    /**
     * @notice Transfer tokens to another address.
     * @param to Recipient address.
     * @param amount Amount in base units (wei equivalent for tokens).
     *
     * @dev SECURITY: Solidity 0.8.x has built-in overflow/underflow protection.
     *      In older versions (pre-0.8.x), without SafeMath, an attacker could
     *      wrap a uint256 around zero to give themselves a massive balance.
     *      Using 0.8.x makes this impossible by default.
     */
    function transfer(address to, uint256 amount)
        external
        validAddress(to)
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @notice Approve a spender to use up to a specified amount of your tokens.
     * @param spender The address being approved to spend.
     * @param amount The maximum amount the spender may use.
     *
     * @dev SECURITY - Approval race condition:
     *      If Alice approves Bob for 100 tokens, then changes it to 50,
     *      Bob could front-run the second approval and spend 100 + 50 = 150 tokens.
     *      The standard mitigation is to set allowance to 0 first, then set the new value.
     *      This contract documents the risk — a production implementation would enforce it.
     */
    function approve(address spender, uint256 amount)
        external
        validAddress(spender)
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Transfer tokens on behalf of another address (requires prior approval).
     * @param from The address to transfer from.
     * @param to The recipient address.
     * @param amount The amount to transfer.
     */
    function transferFrom(address from, address to, uint256 amount)
        external
        validAddress(from)
        validAddress(to)
        returns (bool)
    {
        uint256 currentAllowance = _allowances[from][msg.sender];
        if (amount > currentAllowance) revert InsufficientAllowance(amount, currentAllowance);

        // SECURITY: Reduce allowance before transfer to prevent double-spending.
        _allowances[from][msg.sender] = currentAllowance - amount;

        _transfer(from, to, amount);
        return true;
    }

    // -------------------------------------------------------------------------
    // Owner functions
    // -------------------------------------------------------------------------

    /**
     * @notice Mint new tokens and send them to a specified address.
     * @param to Recipient of the newly minted tokens.
     * @param amount Amount of full tokens to mint (will be scaled by 10**18).
     *
     * @dev SECURITY: Only the owner can mint. Without this restriction,
     *      anyone could inflate the supply and devalue existing holders' tokens.
     *      The maxSupply cap prevents even the owner from minting beyond the limit.
     */
    function mint(address to, uint256 amount)
        external
        onlyOwner
        validAddress(to)
    {
        if (amount == 0) revert ZeroAmount();

        uint256 scaledAmount = amount * (10 ** decimals);
        uint256 remaining = maxSupply - totalSupply;

        if (scaledAmount > remaining) revert MaxSupplyExceeded(scaledAmount, remaining);

        // EFFECTS before INTERACTIONS
        totalSupply += scaledAmount;
        _balances[to] += scaledAmount;

        emit Minted(to, scaledAmount);
        emit Transfer(address(0), to, scaledAmount);
    }

    // -------------------------------------------------------------------------
    // Internal functions
    // -------------------------------------------------------------------------

    /// @dev Internal transfer logic shared by transfer() and transferFrom().
    function _transfer(address from, address to, uint256 amount) internal {
        if (amount == 0) revert ZeroAmount();

        uint256 fromBalance = _balances[from];
        if (amount > fromBalance) revert InsufficientBalance(amount, fromBalance);

        // EFFECTS
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }
}
