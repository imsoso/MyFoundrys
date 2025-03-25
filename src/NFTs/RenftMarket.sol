// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/EIP712.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

/**
 * @title RenftMarket
 * @dev NFT Rental Marketplace Contract
 *   TODO:
 *      1. Return NFT: The tenant can return the NFT at any time during the rental period.
 *         The rent will be calculated based on the rental duration, and the remaining rent will be refunded to the lessor.
 *      2. Expired Order Handling:
 *      3. Claim Rent: The lessor can claim the rent at any time.
 */
contract RenftMarket is EIP712 {
    // Event emitted when an NFT is borrowed
    event BorrowNFT(address indexed taker, address indexed maker, bytes32 orderHash, uint256 collateral);
    // Event emitted when an order is canceled
    event OrderCanceled(address indexed maker, bytes32 orderHash);


    // Type hash for the RentoutOrder struct (must match the struct definition)
    bytes32 private constant RENTOUT_ORDER_TYPEHASH =
        keccak256(
            'RentoutOrder(address maker,address nft_ca,uint256 token_id,uint256 daily_rent,uint256 max_rental_duration,uint256 min_collateral,uint256 list_endtime)'
        );
    mapping(bytes32 => BorrowOrder) public orders; // Active rental orders
    mapping(bytes32 => bool) public canceledOrders; // Canceled orders

    constructor() EIP712('RenftMarket', '1') {}

    /**
     * @notice Borrow an NFT
     * @dev After verifying the signature, transfer the NFT from the lessor to the tenant and store the order details.
     */
    function borrow(RentoutOrder calldata order, bytes calldata makerSignature) external payable {
        revert('TODO');
    }

    /**
     * 1. When canceling an order, ensure the cancellation is recorded on-chain to prevent the order from being reused.
     * 2. DOS Protection: Canceling an order should incur a cost to prevent spamming.
     */
    function cancelOrder(RentoutOrder calldata order, bytes calldata makerSignatre) external {
        revert('TODO');
    }

    // Compute the order hash
    function orderHash(RentoutOrder calldata order) public view returns (bytes32) {
        // Encode the order data into a struct hash
        bytes32 structHash = keccak256(
            abi.encode(
                RENTOUT_ORDER_TYPEHASH,
                order.maker,
                order.nft_ca,
                order.token_id,
                order.daily_rent,
                order.max_rental_duration,
                order.min_collateral,
                order.list_endtime
            )
        );

        // Combine with domain separator for final EIP-712 hash
        return _hashTypedDataV4(structHash);
    }

    struct RentoutOrder {
        address maker; // Lender's address
        address nft_ca; // NFT contract address
        uint256 token_id; // NFT tokenId
        uint256 daily_rent; // Daily rent price
        uint256 max_rental_duration; // Maximum rental duration
        uint256 min_collateral; // Minimum required collateral
        uint256 list_endtime; // Listing expiration time
    }

    // Rental order details
    struct BorrowOrder {
        address taker; // Renter's address
        uint256 collateral; // Collateral amount
        uint256 start_time; // Rental start time (used for rent calculation)
        RentoutOrder rentinfo; // Original rental order
    }
}
