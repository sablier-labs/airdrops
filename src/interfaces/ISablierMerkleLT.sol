// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";

import { MerkleLT } from "./../types/DataTypes.sol";
import { ISablierMerkleBase } from "./ISablierMerkleBase.sol";

/// @title ISablierMerkleLT
/// @notice Merkle Lockup enables airdrops with a vesting period powered by the Lockup Tranched distribution model.
interface ISablierMerkleLT is ISablierMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the admin aborts the recipients.
    event Abort(address[] recipients);

    /// @notice Emitted when a recipient claims a stream.
    event Claim(uint256 index, address indexed recipient, uint128 amount, uint256 indexed streamId);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The address of the {SablierLockup} contract.
    function LOCKUP() external view returns (ISablierLockup);

    /// @notice A flag indicating whether the streams can be canceled.
    /// @dev This is an immutable state variable.
    function STREAM_CANCELABLE() external returns (bool);

    /// @notice The start time of the streams created through {SablierMerkleBase.claim} function.
    /// @dev A start time value of zero will be treated as `block.timestamp`.
    function STREAM_START_TIME() external returns (uint40);

    /// @notice A flag indicating whether the stream NFTs are transferable.
    /// @dev This is an immutable state variable.
    function STREAM_TRANSFERABLE() external returns (bool);

    /// @notice The total percentage of the tranches.
    function TOTAL_PERCENTAGE() external view returns (uint64);

    /// @notice Retrieves the timestamp when the recipient has been aborted by the admin.
    /// @dev A timestamp of zero means the recipient has not been aborted.
    function abortTimes(address recipient) external view returns (uint40);

    /// @notice Retrieves the tranches with their respective unlock percentages and durations.
    function getTranchesWithPercentages() external view returns (MerkleLT.TrancheWithPercentage[] memory);

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Aborts the airdrops for the specified recipients.
    /// @dev Emits an {Abort} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    /// - The campaign must not have expired.
    /// - The campaign must be cancelable.
    ///
    /// @param recipients The recipients to abort.
    function abort(address[] memory recipients) external;
}
