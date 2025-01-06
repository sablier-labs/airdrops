// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ud60x18, ZERO } from "@prb/math/src/UD60x18.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { VestingMath } from "@sablier/lockup/src/libraries/VestingMath.sol";
import { Broker, Lockup, LockupLinear } from "@sablier/lockup/src/types/DataTypes.sol";

import { SablierMerkleBase } from "./abstracts/SablierMerkleBase.sol";
import { ISablierMerkleLL } from "./interfaces/ISablierMerkleLL.sol";
import { Errors } from "./libraries/Errors.sol";
import { MerkleBase, MerkleLL } from "./types/DataTypes.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝

███╗   ███╗███████╗██████╗ ██╗  ██╗██╗     ███████╗    ██╗     ██╗
████╗ ████║██╔════╝██╔══██╗██║ ██╔╝██║     ██╔════╝    ██║     ██║
██╔████╔██║█████╗  ██████╔╝█████╔╝ ██║     █████╗      ██║     ██║
██║╚██╔╝██║██╔══╝  ██╔══██╗██╔═██╗ ██║     ██╔══╝      ██║     ██║
██║ ╚═╝ ██║███████╗██║  ██║██║  ██╗███████╗███████╗    ███████╗███████╗
╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚══════╝╚══════╝

 */

/// @title SablierMerkleLL
/// @notice See the documentation in {ISablierMerkleLL}.
contract SablierMerkleLL is
    ISablierMerkleLL, // 2 inherited components
    SablierMerkleBase // 4 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLL
    ISablierLockup public immutable override LOCKUP;

    /// @inheritdoc ISablierMerkleLL
    bool public immutable override STREAM_CANCELABLE;

    /// @inheritdoc ISablierMerkleLL
    bool public immutable override STREAM_TRANSFERABLE;

    /// @inheritdoc ISablierMerkleLL
    mapping(address recipient => uint40 time) public abortTimes;

    /// @dev See the documentation in {ISablierMerkleLL.getSchedule}.
    MerkleLL.Schedule private _schedule;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Constructs the contract by initializing the immutable state variables, and max approving the Lockup
    /// contract.
    constructor(
        MerkleBase.ConstructorParams memory baseParams,
        ISablierLockup lockup,
        bool cancelable,
        bool transferable,
        MerkleLL.Schedule memory schedule,
        uint256 fee
    )
        SablierMerkleBase(baseParams, fee)
    {
        LOCKUP = lockup;
        STREAM_CANCELABLE = cancelable;
        STREAM_TRANSFERABLE = transferable;
        _schedule = schedule;

        // Max approve the Lockup contract to spend funds from the MerkleLL contract.
        TOKEN.forceApprove(address(LOCKUP), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLL
    function getSchedule() external view override returns (MerkleLL.Schedule memory) {
        return _schedule;
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLL
    function abort(address[] memory recipients) external override onlyAdmin {
        // Check: the campaign has not expired.
        if (hasExpired()) {
            revert Errors.SablierMerkleBase_CampaignExpired({ blockTimestamp: block.timestamp, expiration: EXPIRATION });
        }

        // Check: the campaign is cancelable.
        if (!STREAM_CANCELABLE) {
            revert Errors.SablierMerkleLL_NotCancelableCampaign();
        }

        uint256 count = recipients.length;

        // Set the abort time for each recipient.
        for (uint256 i = 0; i < count; ++i) {
            abortTimes[recipients[i]] = uint40(block.timestamp);
        }

        // Log the abort.
        emit Abort(recipients);
    }

    /*//////////////////////////////////////////////////////////////////////////
                          INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc SablierMerkleBase
    function _claim(uint256 index, address recipient, uint128 amount) internal override {
        // Calculate the timestamps for the stream.
        Lockup.Timestamps memory timestamps;
        if (_schedule.startTime == 0) {
            timestamps.start = uint40(block.timestamp);
        } else {
            timestamps.start = _schedule.startTime;
        }

        uint40 cliffTime;

        // It is safe to use unchecked arithmetic because the `createWithTimestamps` function in the Lockup contract
        // will nonetheless make the relevant checks.
        unchecked {
            if (_schedule.cliffDuration > 0) {
                cliffTime = timestamps.start + _schedule.cliffDuration;
            }
            timestamps.end = timestamps.start + _schedule.totalDuration;
        }

        // Calculate the unlock amounts based on the percentages.
        LockupLinear.UnlockAmounts memory unlockAmounts;
        unlockAmounts.start = ud60x18(amount).mul(_schedule.startPercentage.intoUD60x18()).intoUint128();
        unlockAmounts.cliff = ud60x18(amount).mul(_schedule.cliffPercentage.intoUD60x18()).intoUint128();

        uint256 streamId;

        if (abortTimes[recipient] > 0) {
            uint128 claimableAmount = VestingMath.calculateLockupLinearStreamedAmount({
                depositedAmount: amount,
                blockTimestamp: abortTimes[recipient],
                timestamps: timestamps,
                cliffTime: cliffTime,
                unlockAmounts: unlockAmounts,
                withdrawnAmount: 0
            });

            amount = claimableAmount;
        } else {
            // Interaction: create the stream via {SablierLockup}.
            streamId = LOCKUP.createWithTimestampsLL(
                Lockup.CreateWithTimestamps({
                    sender: admin,
                    recipient: recipient,
                    totalAmount: amount,
                    token: TOKEN,
                    cancelable: STREAM_CANCELABLE,
                    transferable: STREAM_TRANSFERABLE,
                    timestamps: timestamps,
                    shape: string(abi.encodePacked(SHAPE)),
                    broker: Broker({ account: address(0), fee: ZERO })
                }),
                unlockAmounts,
                cliffTime
            );
        }

        // Log the claim.
        emit Claim(index, recipient, amount, streamId);
    }
}
