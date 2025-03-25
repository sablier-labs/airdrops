// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD2x18 } from "@prb/math/src/UD2x18.sol";

import { ISablierMerkleLockup } from "./ISablierMerkleLockup.sol";

/// @title ISablierMerkleLL
/// @notice MerkleLL enables an airdrop model with a vesting period powered by the Lockup Linear model.
interface ISablierMerkleLL is ISablierMerkleLockup {
    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    ///@notice Returns the duration of the cliff in seconds.
    function CLIFF_DURATION() external view returns (uint40);

    /// @notice Returns the percentage of the claim amount to be unlocked at cliff time, as a fixed-point number where
    /// 1e18 is 100%.
    function CLIFF_UNLOCK_PERCENTAGE() external view returns (UD2x18);

    /// @notice Returns the start time of the stream. Zero is a sentinel value for `block.timestamp`.
    function START_TIME() external view returns (uint40);

    /// @notice Returns the percentage of the claim amount to be unlocked at start time, as a fixed-point number where
    /// 1e18 is 100%.
    function START_UNLOCK_PERCENTAGE() external view returns (UD2x18);

    /// @notice Returns the total duration of the stream in seconds.
    function TOTAL_DURATION() external view returns (uint40);
}
