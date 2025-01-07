// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { MerkleLL } from "./../types/DataTypes.sol";
import { ISablierMerkleBase } from "./ISablierMerkleBase.sol";

/// @title ISablierMerkleLL
/// @notice Merkle Lockup enables airdrops with a vesting period powered by the Lockup Linear distribution model.
interface ISablierMerkleLL is ISablierMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the admin aborts the recipients.
    event Abort(address[] recipients);

    /// @notice Emitted when a recipient claims a stream.
    /// @dev A stream ID of zero means that the recipient has been aborted and no stream was created.
    event Claim(uint256 index, address indexed recipient, uint128 amount, uint256 indexed streamId);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The address of the {SablierLockup} contract.
    function LOCKUP() external view returns (ISablierLockup);

    /// @notice A flag indicating whether the streams can be canceled.
    /// @dev This is an immutable state variable.
    function STREAM_CANCELABLE() external returns (bool);

    /// @notice A flag indicating whether the stream NFTs are transferable.
    /// @dev This is an immutable state variable.
    function STREAM_TRANSFERABLE() external returns (bool);

    /// @notice Retrieves the timestamp when the recipient has been aborted by the admin.
    /// @dev A timestamp of zero means the recipient has not been aborted.
    function abortTimes(address recipient) external view returns (uint40);

    /// @notice A tuple containing the start time, start unlock percentage, cliff duration, cliff unlock percentage, and
    /// end duration. These values are used to calculate the vesting schedule in `Lockup.CreateWithTimestampsLL`.
    /// @dev A start time value of zero will be considered as `block.timestamp`.
    function getSchedule() external view returns (MerkleLL.Schedule memory);

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
