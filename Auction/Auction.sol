// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Auction
 * @author Vektasafe
 * @notice A timed auction where users compete by bidding ETH.
 *         When the auction ends, the highest bidder wins and the seller
 *         receives the funds. All losing bidders can withdraw their bids.
 *
 * Security considerations documented inline throughout this contract.
 * This contract is a learning artefact and is not intended for production use.
 */
contract Auction {

    // -------------------------------------------------------------------------
    // State variables
    // -------------------------------------------------------------------------

    /// @notice The address that created the auction and will receive the winning bid.
    address payable public immutable seller;

    /// @notice The Unix timestamp at which the auction ends.
    uint256 public immutable endTime;

    /// @notice Description of the item being auctioned.
    string public itemDescription;

    /// @notice The highest bid received so far.
    uint256 public highestBid;

    /// @notice The address of the current highest bidder.
    address public highestBidder;

    /// @notice Whether the auction has been finalised.
    bool public ended;

    /// @dev SECURITY - Pull-over-push refund pattern:
    ///      Instead of pushing ETH to losing bidders immediately (which allows
    ///      a malicious bidder's contract to revert and block the auction),
    ///      we store pending refunds here. Each user must call withdraw() themselves.
    ///      This is called the "pull" pattern and is the industry standard for refunds.
    mapping(address => uint256) private pendingRefunds;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    event BidPlaced(address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed winner, uint256 amount);
    event Withdrawn(address indexed bidder, uint256 amount);

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    error AuctionAlreadyEnded();
    error AuctionNotYetEnded();
    error BidTooLow(uint256 submitted, uint256 required);
    error ZeroAmount();
    error NothingToWithdraw();
    error TransferFailed();
    error AlreadyFinalised();

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /**
     * @param durationSeconds How long the auction runs in seconds from deployment.
     * @param _itemDescription A short description of the item being auctioned.
     *
     * @dev SECURITY - Timestamp dependence:
     *      block.timestamp can be manipulated by miners by up to ~15 seconds.
     *      For short auctions this could matter, but for durations measured in
     *      hours or days the risk is negligible. For high-value auctions,
     *      block number is sometimes preferred over timestamp.
     */
    constructor(uint256 durationSeconds, string memory _itemDescription) {
        seller = payable(msg.sender);
        endTime = block.timestamp + durationSeconds;
        itemDescription = _itemDescription;
    }

    // -------------------------------------------------------------------------
    // External functions
    // -------------------------------------------------------------------------

    /**
     * @notice Place a bid. Must be higher than the current highest bid.
     *
     * @dev SECURITY - Reentrancy:
     *      We follow Checks-Effects-Interactions strictly.
     *      The previous highest bidder's refund is stored in pendingRefunds (effect)
     *      BEFORE any ETH movement. No external call happens during bid placement.
     *
     * @dev SECURITY - Denial of service via revert:
     *      If we refunded the previous bidder immediately here using .call(),
     *      a malicious bidder could deploy a contract that reverts on receive(),
     *      permanently blocking new bids. By using pendingRefunds instead,
     *      the auction cannot be blocked by any single participant.
     */
    function bid() external payable {
        // CHECKS
        if (block.timestamp >= endTime) revert AuctionAlreadyEnded();
        if (msg.value == 0) revert ZeroAmount();
        if (msg.value <= highestBid) revert BidTooLow(msg.value, highestBid + 1);

        // EFFECTS -- update state before any transfers
        if (highestBidder != address(0)) {
            // Queue the previous highest bidder's refund for them to pull later
            pendingRefunds[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;

        emit BidPlaced(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw a pending refund after being outbid.
     *
     * @dev SECURITY - Reentrancy protection via CEI:
     *      We zero the refund balance (effect) BEFORE sending ETH (interaction).
     *      If we sent first and then zeroed, a reentrant call could drain the contract
     *      by calling withdraw() repeatedly before the balance is zeroed.
     */
    function withdraw() external {
        // CHECKS
        uint256 refund = pendingRefunds[msg.sender];
        if (refund == 0) revert NothingToWithdraw();

        // EFFECTS -- zero the balance before the external call
        pendingRefunds[msg.sender] = 0;

        // INTERACTIONS -- ETH transfer happens last
        (bool success, ) = msg.sender.call{value: refund}("");
        if (!success) revert TransferFailed();

        emit Withdrawn(msg.sender, refund);
    }

    /**
     * @notice Finalise the auction and transfer the winning bid to the seller.
     * @dev Can be called by anyone after the auction ends.
     *      The seller does not need to be the one to finalise.
     *
     * @dev SECURITY: The `ended` flag prevents this function from being called
     *      twice. Without it, the seller could receive double payment if the
     *      function were called repeatedly. This is a simple but important guard.
     */
    function finalise() external {
        // CHECKS
        if (block.timestamp < endTime) revert AuctionNotYetEnded();
        if (ended) revert AlreadyFinalised();

        // EFFECTS
        ended = true;

        emit AuctionEnded(highestBidder, highestBid);

        // INTERACTIONS
        if (highestBid > 0) {
            (bool success, ) = seller.call{value: highestBid}("");
            if (!success) revert TransferFailed();
        }
    }

    // -------------------------------------------------------------------------
    // View functions
    // -------------------------------------------------------------------------

    /// @notice Returns the pending refund available for a given address.
    function getPendingRefund(address bidder) external view returns (uint256) {
        return pendingRefunds[bidder];
    }

    /// @notice Returns the time remaining in the auction in seconds.
    ///         Returns zero if the auction has already ended.
    function timeRemaining() external view returns (uint256) {
        if (block.timestamp >= endTime) return 0;
        return endTime - block.timestamp;
    }
}
