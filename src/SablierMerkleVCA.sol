// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

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
    using SafeCast for uint256;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleVCA
    uint256 public override forgoneAmount;

    /// @dev The vesting schedule encapsulating the start time and end time of the airdrop unlocks.
    MerkleVCA.Timestamps private _vestingSchedule;

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
        // Check: neither vesting start time nor vesting end time is zero.
        if (params.vesting.end == 0 || params.vesting.start == 0) {
            revert Errors.SablierMerkleVCA_VestingTimeZero({
                startTime: params.vesting.start,
                endTime: params.vesting.end
            });
        }

        // Check: vesting end time is not less than the start time.
        if (params.vesting.end < params.vesting.start) {
            revert Errors.SablierMerkleVCA_VestingStartTimeExceedsEndTime({
                startTime: params.vesting.start,
                endTime: params.vesting.end
            });
        }

        // Check: campaign expiration, if non-zero, exceeds the vesting end time by at least 1 week.
        if (params.expiration > 0 && params.expiration < params.vesting.end + 1 weeks) {
            revert Errors.SablierMerkleVCA_ExpiryWithinOneWeekOfVestingEnd({
                endTime: params.vesting.end,
                expiration: params.expiration
            });
        }

        _vestingSchedule = params.vesting;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleVCA
    function vestingSchedule() external view override returns (MerkleVCA.Timestamps memory) {
        return _vestingSchedule;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc SablierMerkleBase
    function _claim(uint256 index, address recipient, uint128 amount) internal override {
        uint40 blockTimestamp = uint40(block.timestamp);

        // Check: vesting start time is not in the future.
        if (_vestingSchedule.start >= blockTimestamp) {
            revert Errors.SablierMerkleVCA_ClaimNotStarted();
        }

        uint128 claimableAmount;

        // Calculate the claimable amount.
        if (_vestingSchedule.end <= blockTimestamp) {
            // If the vesting period has ended, the recipient can claim the full amount.
            claimableAmount = amount;
        } else {
            // Otherwise, calculate the claimable amount based on the elapsed time.
            uint40 elapsedTime = blockTimestamp - _vestingSchedule.start;
            uint40 totalDuration = _vestingSchedule.end - _vestingSchedule.start;

            claimableAmount = ((uint256(amount) * elapsedTime) / totalDuration).toUint128();

            // Effect: update the forgone amount.
            forgoneAmount += (amount - claimableAmount);
        }

        // Interaction: transfer the tokens to the recipient.
        TOKEN.safeTransfer({ to: recipient, value: claimableAmount });

        // Log the claim.
        emit Claim(index, recipient, claimableAmount, amount);
    }
}
