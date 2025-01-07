// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

/// @title Errors
/// @notice Library containing all custom errors the protocol may revert with.
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                    GENERIC
    //////////////////////////////////////////////////////////////////////////*/

    error CallerNotAdmin(address admin, address caller);

    /*//////////////////////////////////////////////////////////////////////////
                                SABLIER-MERKLE-BASE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when caller is not the factory contract.
    error SablierMerkleBase_CallerNotFactory(address factory, address caller);

    /// @notice Thrown when trying to claim after the campaign has expired.
    error SablierMerkleBase_CampaignExpired(uint256 blockTimestamp, uint40 expiration);

    /// @notice Thrown when trying to clawback when the current timestamp is over the grace period and the campaign has
    /// not expired.
    error SablierMerkleBase_ClawbackNotAllowed(uint256 blockTimestamp, uint40 expiration, uint40 firstClaimTime);

    /// @notice Thrown if the fees withdrawal failed.
    error SablierMerkleBase_FeeTransferFail(address factoryAdmin, uint256 feeAmount);

    /// @notice Thrown when trying to claim with an insufficient fee payment.
    error SablierMerkleBase_InsufficientFeePayment(uint256 feePaid, uint256 fee);

    /// @notice Thrown when trying to claim with an invalid Merkle proof.
    error SablierMerkleBase_InvalidProof();

    /// @notice Thrown when trying to claim the same stream more than once.
    error SablierMerkleBase_StreamClaimed(uint256 index);

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-MERKLE-LL
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to abort when the campaign is not cancelable.
    error SablierMerkleLL_NotCancelableCampaign();

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-MERKLE-LT
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to abort when the campaign is not cancelable.
    error SablierMerkleLT_NotCancelableCampaign();

    /// @notice Thrown when trying to claim from an LT campaign with tranches' unlock percentages not adding up to 100%.
    error SablierMerkleLT_TotalPercentageNotOneHundred(uint64 totalPercentage);
}
