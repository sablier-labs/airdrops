// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { MerkleVCA } from "../types/DataTypes.sol";
import { ISablierMerkleBase } from "./ISablierMerkleBase.sol";

/// @title ISablierMerkleVCA
/// @notice VCA (Variable Claim Amount) is an airdrop model where the claimable amount increases linearly
/// until the airdrop period ends. Claiming early results in forgoing the remaining amount, whereas claiming
/// after the period grants the full allocation.
interface ISablierMerkleVCA is ISablierMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a recipient claims the airdrop.
    event Claim(uint256 index, address indexed recipient, uint128 claimAmount, uint128 forgoneAmount);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the amount that would be claimed if the claim was made now.
    /// @dev This is for informational purposes only. To actually claim the airdrop, a Merkle proof is required.
    /// @param fullAmount The total amount of tokens claimable after the vesting schedule ends.
    function calculateClaimAmount(uint128 fullAmount) external view returns (uint128);

    /// @notice Retrieves the amount that would be forgone if the claim was made now.
    /// @dev This is for informational purposes only. To actually claim the airdrop, a Merkle proof is required.
    /// @param fullAmount The total amount of tokens claimable after the vesting schedule ends.
    function calculateForgoneAmount(uint128 fullAmount) external view returns (uint128);

    /// @notice Retrieves the start time and end time of the vesting schedule.
    function getSchedule() external view returns (MerkleVCA.Schedule memory);

    /// @notice Retrieves the total amount of tokens forgone by early claimers.
    function totalForgoneAmount() external view returns (uint256);
}
