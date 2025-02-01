// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";

import { ISablierMerkleLockup } from "../interfaces/ISablierMerkleLL.sol";
import { MerkleLockup } from "../types/DataTypes.sol";
import { SablierMerkleBase } from "./SablierMerkleBase.sol";

/// @title SablierMerkleLockup
/// @notice See the documentation in {ISablierMerkleLockup}.
abstract contract SablierMerkleLockup is
    ISablierMerkleLockup, // 2 inherited components,
    SablierMerkleBase // 3 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLockup
    ISablierLockup public immutable override LOCKUP;

    /// @inheritdoc ISablierMerkleLockup
    bytes32 public immutable override SHAPE;

    /// @inheritdoc ISablierMerkleLockup
    bool public immutable override STREAM_CANCELABLE;

    /// @inheritdoc ISablierMerkleLockup
    bool public immutable override STREAM_TRANSFERABLE;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Constructs the contract by initializing the immutable state variables, and max approving the Lockup
    /// contract.
    constructor(
        MerkleLockup.ConstructorParams memory baseParams,
        address campaignCreator
    )
        SablierMerkleBase(
            campaignCreator,
            baseParams.campaignName,
            baseParams.expiration,
            baseParams.initialAdmin,
            baseParams.ipfsCID,
            baseParams.merkleRoot,
            baseParams.token
        )
    {
        LOCKUP = baseParams.lockup;
        SHAPE = baseParams.shape;
        STREAM_CANCELABLE = baseParams.cancelable;
        STREAM_TRANSFERABLE = baseParams.transferable;

        // Max approve the Lockup contract to spend funds from the Merkle Lockup campaigns.
        TOKEN.forceApprove(address(LOCKUP), type(uint256).max);
    }
}
