// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { MerkleVCA } from "../types/DataTypes.sol";
import { ISablierMerkleBase } from "./ISablierMerkleBase.sol";

/// @title ISablierMerkleVCA
/// @notice MerkleVCA enables airdrop distributions where the claimable amount linearly increases over time. If the
/// claim is made at the end of the designated period, the recipient receives the full airdrop allocation.
interface ISablierMerkleVCA is ISablierMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a recipient claims the airdrop.
    event Claim(uint256 index, address indexed recipient, uint128 claimableAmount, uint128 totalAmount);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Calculates the claimable amount at `block.timestamp` for a given maturity amount.
    /// @param maturityAmount The amount of tokens that will be distributed to the recipient if they wait
    /// until the unlock end time.
    /// @return claimAmount The amount of tokens that the recipient can claim.
    function calculateClaimAmount(uint128 maturityAmount) external view returns (uint128 claimAmount);

    /// @notice Calculates the forgone amount at `block.timestamp` for a given maturity amount.
    /// @param maturityAmount The amount of tokens that will be distributed to the recipient if they wait
    /// until the unlock end time.
    /// @return forgoneAmount_ The amount of tokens that the recipient will give up by claiming early.
    function calculateForgoneAmount(uint128 maturityAmount) external view returns (uint128 forgoneAmount_);

    /// @notice Returns the amount of tokens forgone by the early claimers.
    function forgoneAmount() external view returns (uint256);

    /// @notice Returns the start time and end time of the airdrop unlock.
    function timestamps() external view returns (MerkleVCA.Timestamps memory);
}
