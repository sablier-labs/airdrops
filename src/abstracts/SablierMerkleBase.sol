// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { Adminable } from "@sablier/evm-utils/src/Adminable.sol";

import { ISablierMerkleBase } from "./../interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactoryBase } from "./../interfaces/ISablierMerkleFactoryBase.sol";
import { Errors } from "./../libraries/Errors.sol";

/// @title SablierMerkleBase
/// @notice See the documentation in {ISablierMerkleBase}.
abstract contract SablierMerkleBase is
    ISablierMerkleBase, // 1 inherited component
    Adminable // 1 inherited component
{
    using BitMaps for BitMaps.BitMap;
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleBase
    address public immutable override CHAINLINK_PRICE_FEED;

    /// @inheritdoc ISablierMerkleBase
    uint40 public immutable override EXPIRATION;

    /// @inheritdoc ISablierMerkleBase
    address public immutable override FACTORY;

    /// @inheritdoc ISablierMerkleBase
    bytes32 public immutable override MERKLE_ROOT;

    /// @inheritdoc ISablierMerkleBase
    IERC20 public immutable override TOKEN;

    /// @inheritdoc ISablierMerkleBase
    string public override campaignName;

    /// @inheritdoc ISablierMerkleBase
    string public override ipfsCID;

    /// @inheritdoc ISablierMerkleBase
    uint256 public override minimumFee;

    /// @dev Packed booleans that record the history of claims.
    BitMaps.BitMap internal _claimedBitMap;

    /// @dev The timestamp when the first claim is made.
    uint40 internal _firstClaimTime;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Constructs the contract by initializing the immutable state variables.
    constructor(
        address campaignCreator,
        string memory _campaignName,
        uint40 expiration,
        address initialAdmin,
        string memory _ipfsCID,
        bytes32 merkleRoot,
        IERC20 token
    )
        Adminable(initialAdmin)
    {
        FACTORY = msg.sender;
        CHAINLINK_PRICE_FEED = ISablierMerkleFactoryBase(FACTORY).chainlinkPriceFeed();
        EXPIRATION = expiration;
        MERKLE_ROOT = merkleRoot;
        TOKEN = token;
        campaignName = _campaignName;
        ipfsCID = _ipfsCID;
        minimumFee = ISablierMerkleFactoryBase(FACTORY).getFee(campaignCreator);
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleBase
    function calculateMinimumFeeInWei() external view returns (uint256) {
        return _calculateMinimumFeeInWei();
    }

    /// @inheritdoc ISablierMerkleBase
    function getFirstClaimTime() external view override returns (uint40) {
        return _firstClaimTime;
    }

    /// @inheritdoc ISablierMerkleBase
    function hasClaimed(uint256 index) public view override returns (bool) {
        return _claimedBitMap.get(index);
    }

    /// @inheritdoc ISablierMerkleBase
    function hasExpired() public view override returns (bool) {
        return EXPIRATION > 0 && EXPIRATION <= block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleBase
    function claim(
        uint256 index,
        address recipient,
        uint128 amount,
        bytes32[] calldata merkleProof
    )
        external
        payable
        override
    {
        // Check: the campaign has not expired.
        if (hasExpired()) {
            revert Errors.SablierMerkleBase_CampaignExpired({ blockTimestamp: block.timestamp, expiration: EXPIRATION });
        }

        // Calculate the minimum fee in wei.
        uint256 minimumFeeInWei = _calculateMinimumFeeInWei();

        // Check: `msg.value` is not less than the minimum fee.
        if (msg.value < minimumFeeInWei) {
            revert Errors.SablierMerkleBase_InsufficientFeePayment(msg.value, minimumFeeInWei);
        }

        // Check: the index has not been claimed.
        if (_claimedBitMap.get(index)) {
            revert Errors.SablierMerkleBase_StreamClaimed(index);
        }

        // Generate the Merkle tree leaf by hashing the corresponding parameters. Hashing twice prevents second
        // preimage attacks.
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(index, recipient, amount))));

        // Check: the input claim is included in the Merkle tree.
        if (!MerkleProof.verify(merkleProof, MERKLE_ROOT, leaf)) {
            revert Errors.SablierMerkleBase_InvalidProof();
        }

        // Effect: set the `_firstClaimTime` if its zero.
        if (_firstClaimTime == 0) {
            _firstClaimTime = uint40(block.timestamp);
        }

        // Effect: mark the index as claimed.
        _claimedBitMap.set(index);

        // Call the internal virtual function.
        _claim(index, recipient, amount);
    }

    /// @inheritdoc ISablierMerkleBase
    function clawback(address to, uint128 amount) external override onlyAdmin {
        // Check: current timestamp is over the grace period and the campaign has not expired.
        if (_hasGracePeriodPassed() && !hasExpired()) {
            revert Errors.SablierMerkleBase_ClawbackNotAllowed({
                blockTimestamp: block.timestamp,
                expiration: EXPIRATION,
                firstClaimTime: _firstClaimTime
            });
        }

        // Effect: transfer the tokens to the provided address.
        TOKEN.safeTransfer({ to: to, value: amount });

        // Log the clawback.
        emit Clawback(admin, to, amount);
    }

    /// @inheritdoc ISablierMerkleBase
    function collectFees(address factoryAdmin) external override returns (uint256 feeAmount) {
        // Check: the caller is the FACTORY.
        if (msg.sender != address(FACTORY)) {
            revert Errors.SablierMerkleBase_CallerNotFactory(address(FACTORY), msg.sender);
        }

        feeAmount = address(this).balance;

        // Effect: transfer the fees to the factory admin.
        (bool success,) = factoryAdmin.call{ value: feeAmount }("");

        // Revert if the call failed.
        if (!success) {
            revert Errors.SablierMerkleBase_FeeTransferFail(factoryAdmin, feeAmount);
        }
    }

    /// @inheritdoc ISablierMerkleBase
    function setMinimumFeeToZero() external override {
        // Retrieve the factory admin.
        address factoryAdmin = ISablierMerkleFactoryBase(FACTORY).admin();

        // Check: the caller is the factory admin.
        if (msg.sender != factoryAdmin) {
            revert Errors.SablierMerkleBase_CallerNotFactoryAdmin(factoryAdmin, msg.sender);
        }

        uint256 previousMinimumFee = minimumFee;

        // Effect: set the minimum fee to zero.
        minimumFee = 0;

        // Log the event.
        emit MinimumFeeSetToZero(factoryAdmin, previousMinimumFee);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _calculateMinimumFeeInWei() internal view returns (uint256) {
        // If the Chainlink price feed is not set, return 0.
        if (CHAINLINK_PRICE_FEED == address(0)) {
            return 0;
        }

        // If the minimum fee is 0, return 0.
        if (minimumFee == 0) {
            return 0;
        }

        // Q: should we do a low-level call here instead?
        (, int256 price,,,) = AggregatorV3Interface(CHAINLINK_PRICE_FEED).latestRoundData();
        // Q: should we check the price is greater than 0 ? If yes, should we revert?

        // Calculate the minimum fee in wei.
        return 1e18 * minimumFee / uint256(price);
    }

    /// @notice Returns a flag indicating whether the grace period has passed.
    /// @dev The grace period is 7 days after the first claim.
    function _hasGracePeriodPassed() internal view returns (bool) {
        return _firstClaimTime > 0 && block.timestamp > _firstClaimTime + 7 days;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev This function is implemented by child contracts, so the logic varies depending on the model.
    function _claim(uint256 index, address recipient, uint128 amount) internal virtual;
}
