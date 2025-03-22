// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { SablierMerkleBase } from "./abstracts/SablierMerkleBase.sol";
import { ISablierMerkleVCA } from "./interfaces/ISablierMerkleVCA.sol";
import { Errors } from "./libraries/Errors.sol";
import { MerkleVCA } from "./types/DataTypes.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝

███╗   ███╗███████╗██████╗ ██╗  ██╗██╗     ███████╗    ██╗   ██╗ ██████╗ █████╗
████╗ ████║██╔════╝██╔══██╗██║ ██╔╝██║     ██╔════╝    ██║   ██║██╔════╝██╔══██╗
██╔████╔██║█████╗  ██████╔╝█████╔╝ ██║     █████╗      ██║   ██║██║     ███████║
██║╚██╔╝██║██╔══╝  ██╔══██╗██╔═██╗ ██║     ██╔══╝      ╚██╗ ██╔╝██║     ██╔══██║
██║ ╚═╝ ██║███████╗██║  ██║██║  ██╗███████╗███████╗     ╚████╔╝ ╚██████╗██║  ██║
╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝      ╚═══╝   ╚═════╝╚═╝  ╚═╝

*/

/// @title SablierMerkleVCA
/// @notice See the documentation in {ISablierMerkleVCA}.
contract SablierMerkleVCA is
    ISablierMerkleVCA, // 2 inherited components
    SablierMerkleBase // 3 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleVCA
    uint256 public override forgoneAmount;

    /// @dev The timestamps variable encapsulates the start time and end time of the airdrop unlock.
    MerkleVCA.Timestamps private _timestamp;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Constructs the contract by initializing the immutable state variables.
    constructor(
        MerkleVCA.ConstructorParams memory params,
        address campaignCreator
    )
        SablierMerkleBase(
            campaignCreator,
            params.campaignName,
            params.expiration,
            params.initialAdmin,
            params.ipfsCID,
            params.merkleRoot,
            params.token
        )
    {
        // Check: unlock start time is not zero.
        if (params.timestamps.start == 0) {
            revert Errors.SablierMerkleVCA_StartTimeZero();
        }

        // Check: unlock end time is greater than the start time.
        if (params.timestamps.end <= params.timestamps.start) {
            revert Errors.SablierMerkleVCA_StartTimeExceedsEndTime({
                startTime: params.timestamps.start,
                endTime: params.timestamps.end
            });
        }

        // Check: campaign expiration is not zero.
        if (params.expiration == 0) {
            revert Errors.SablierMerkleVCA_ExpiryTimeZero();
        }

        // Check: campaign expiration exceeds the timestamps end time by at least 1 week.
        if (params.expiration < params.timestamps.end + 1 weeks) {
            revert Errors.SablierMerkleVCA_ExpiryWithinOneWeekOfUnlockEndTime({
                endTime: params.timestamps.end,
                expiration: params.expiration
            });
        }

        _timestamp = params.timestamps;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleVCA
    function calculateClaimAmount(uint128 maturityAmount) public view override returns (uint128 claimAmount) {
        // If the unlock start time is in the future, the recipient cannot claim any tokens.
        if (_timestamp.start >= block.timestamp) {
            return 0;
        }
        // Otherwise, calculate the claimable amount.
        claimAmount = _calculateClaimAmount(maturityAmount);
    }

    /// @inheritdoc ISablierMerkleVCA
    function calculateForgoneAmount(uint128 maturityAmount) external view override returns (uint128 forgoneAmount_) {
        forgoneAmount_ = maturityAmount - calculateClaimAmount(maturityAmount);
    }

    /// @inheritdoc ISablierMerkleVCA
    function timestamps() external view override returns (MerkleVCA.Timestamps memory) {
        return _timestamp;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _calculateClaimAmount(uint128 maturityAmount) internal view returns (uint128 claimAmount) {
        uint40 blockTimestamp = uint40(block.timestamp);

        // Load the timestamps in memory.
        MerkleVCA.Timestamps memory timestamp = _timestamp;

        // Calculate the claimable amount.
        if (timestamp.end <= blockTimestamp) {
            // If the unlock period has ended, the recipient can claim the full amount.
            return maturityAmount;
        } else {
            // Otherwise, calculate the claimable amount based on the elapsed time.
            uint40 elapsedTime = blockTimestamp - timestamp.start;
            uint40 totalDuration = timestamp.end - timestamp.start;

            // Safe to cast because the division results into a value less than `amount` which is already an `uint128`.
            claimAmount = uint128((uint256(maturityAmount) * elapsedTime) / totalDuration);
        }
    }

    /// @inheritdoc SablierMerkleBase
    function _claim(uint256 index, address recipient, uint128 amount) internal override {
        // Check: unlock start time is in the past.
        if (_timestamp.start >= block.timestamp) {
            revert Errors.SablierMerkleVCA_ClaimNotStarted(_timestamp.start);
        }

        // Calculate the claimable amount.
        uint128 claimableAmount = _calculateClaimAmount(amount);

        // Effect: update the forgone amount.
        forgoneAmount += (amount - claimableAmount);

        // Interaction: transfer the tokens to the recipient.
        TOKEN.safeTransfer({ to: recipient, value: claimableAmount });

        // Log the claim.
        emit Claim(index, recipient, claimableAmount, amount);
    }
}
