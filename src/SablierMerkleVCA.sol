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
        // Check: vesting start time is not in the future.
        if (_vestingSchedule.start >= block.timestamp) {
            revert Errors.SablierMerkleVCA_ClaimNotStarted();
        }

        uint128 claimableAmount;

        // Calculate the claimable amount.
        if (_vestingSchedule.end <= block.timestamp) {
            // If the vesting period has ended, the recipient can claim the full amount.
            claimableAmount = amount;
        } else {
            // Otherwise, calculate the claimable amount based on the elapsed time.
            uint40 elapsedTime = uint40(block.timestamp) - _vestingSchedule.start;
            uint40 totalDuration = _vestingSchedule.end - _vestingSchedule.start;

            claimableAmount = ((uint256(amount) * elapsedTime) / totalDuration).toUint128();

            // Effect: update the forgone amount.
            forgoneAmount += (amount - claimableAmount);
        }

        // Interaction: withdraw the tokens to the recipient.
        TOKEN.safeTransfer(recipient, claimableAmount);

        // Log the claim.
        emit Claim(index, recipient, claimableAmount, amount);
    }
}
