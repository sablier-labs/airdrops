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
    uint40 public immutable override END_TIME;

    /// @inheritdoc ISablierMerkleVCA
    uint40 public immutable override START_TIME;

    /// @inheritdoc ISablierMerkleVCA
    uint256 public override forgoneAmount;

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
        // Check: start time is not zero.
        if (params.startTime == 0) {
            revert Errors.SablierMerkleVCA_StartTimeZero();
        }

        // Check: end time is greater than the start time.
        if (params.endTime <= params.startTime) {
            revert Errors.SablierMerkleVCA_StartTimeExceedsEndTime({
                startTime: params.startTime,
                endTime: params.endTime
            });
        }

        // Check: campaign expiration is not zero.
        if (params.expiration == 0) {
            revert Errors.SablierMerkleVCA_ExpiryTimeZero();
        }

        // Check: campaign expiration exceeds the end time by at least 1 week.
        if (params.expiration < params.endTime + 1 weeks) {
            revert Errors.SablierMerkleVCA_ExpiryWithinOneWeekOfUnlockEndTime({
                endTime: params.endTime,
                expiration: params.expiration
            });
        }

        // Effect: set the end time.
        END_TIME = params.endTime;

        // Effect: set the start time.
        START_TIME = params.startTime;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc SablierMerkleBase
    function _claim(uint256 index, address recipient, uint128 amount) internal override {
        uint40 blockTimestamp = uint40(block.timestamp);

        // Check: start time is in the past.
        if (START_TIME >= blockTimestamp) {
            revert Errors.SablierMerkleVCA_ClaimNotStarted(START_TIME);
        }

        uint128 claimableAmount;

        // Calculate the claimable amount.
        if (END_TIME <= blockTimestamp) {
            // If end time is not in the future, the recipient can claim the full amount.
            claimableAmount = amount;
        } else {
            // Otherwise, calculate the claimable amount based on the elapsed time.
            uint40 elapsedTime = blockTimestamp - START_TIME;
            uint40 totalDuration = END_TIME - START_TIME;

            // Safe to cast because the division results into a value less than `amount` which is already an `uint128`.
            claimableAmount = uint128((uint256(amount) * elapsedTime) / totalDuration);

            // Effect: update the forgone amount.
            forgoneAmount += (amount - claimableAmount);
        }

        // Interaction: transfer the tokens to the recipient.
        TOKEN.safeTransfer({ to: recipient, value: claimableAmount });

        // Log the claim.
        emit Claim(index, recipient, claimableAmount, amount);
    }
}
