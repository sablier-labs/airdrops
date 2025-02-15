// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { ud } from "@prb/math/src/UD60x18.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { LockupTranched } from "@sablier/lockup/src/types/DataTypes.sol";

import { MerkleInstant, MerkleLL, MerkleLT, MerkleVCA } from "../../src/types/DataTypes.sol";

import { Constants } from "./Constants.sol";

/// @notice Contract with default functions used throughout the tests.
contract Defaults is Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                  MERKLE-INSTANT
    //////////////////////////////////////////////////////////////////////////*/

    function merkleInstantConstructorParams(
        address campaignOwner,
        uint40 expiration,
        bytes32 merkleRoot,
        IERC20 token_
    )
        public
        view
        returns (MerkleInstant.ConstructorParams memory)
    {
        return MerkleInstant.ConstructorParams({
            campaignName: CAMPAIGN_NAME,
            expiration: expiration,
            initialAdmin: campaignOwner,
            ipfsCID: IPFS_CID,
            merkleRoot: merkleRoot,
            token: token_
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LL
    //////////////////////////////////////////////////////////////////////////*/

    function merkleLLConstructorParams(
        address campaignOwner,
        uint40 expiration,
        ISablierLockup lockup,
        bytes32 merkleRoot,
        IERC20 token_
    )
        public
        view
        returns (MerkleLL.ConstructorParams memory)
    {
        return MerkleLL.ConstructorParams({
            campaignName: CAMPAIGN_NAME,
            cancelable: CANCELABLE,
            expiration: expiration,
            initialAdmin: campaignOwner,
            ipfsCID: IPFS_CID,
            lockup: lockup,
            merkleRoot: merkleRoot,
            schedule: MerkleLL.Schedule({
                startTime: ZERO,
                startPercentage: START_PERCENTAGE,
                cliffDuration: CLIFF_DURATION,
                cliffPercentage: CLIFF_PERCENTAGE,
                totalDuration: TOTAL_DURATION
            }),
            shape: SHAPE,
            token: token_,
            transferable: TRANSFERABLE
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LT
    //////////////////////////////////////////////////////////////////////////*/

    function merkleLTConstructorParams(
        address campaignOwner,
        uint40 expiration,
        ISablierLockup lockup,
        bytes32 merkleRoot,
        IERC20 token_
    )
        public
        view
        returns (MerkleLT.ConstructorParams memory)
    {
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages_ = new MerkleLT.TrancheWithPercentage[](2);
        tranchesWithPercentages_[0] =
            MerkleLT.TrancheWithPercentage({ unlockPercentage: ud2x18(0.2e18), duration: 2 days });
        tranchesWithPercentages_[1] =
            MerkleLT.TrancheWithPercentage({ unlockPercentage: ud2x18(0.8e18), duration: 8 days });

        return MerkleLT.ConstructorParams({
            campaignName: CAMPAIGN_NAME,
            cancelable: CANCELABLE,
            expiration: expiration,
            initialAdmin: campaignOwner,
            ipfsCID: IPFS_CID,
            lockup: lockup,
            merkleRoot: merkleRoot,
            shape: SHAPE,
            streamStartTime: ZERO,
            token: token_,
            tranchesWithPercentages: tranchesWithPercentages_,
            transferable: TRANSFERABLE
        });
    }

    /// @dev Mirrors the logic from {SablierMerkleLT._calculateStartTimeAndTranches}.
    function tranchesMerkleLT(
        uint40 streamStartTime,
        uint128 totalAmount
    )
        public
        view
        returns (LockupTranched.Tranche[] memory tranches_)
    {
        tranches_ = new LockupTranched.Tranche[](2);
        if (streamStartTime == 0) {
            tranches_[0].timestamp = uint40(block.timestamp) + CLIFF_DURATION;
            tranches_[1].timestamp = uint40(block.timestamp) + TOTAL_DURATION;
        } else {
            tranches_[0].timestamp = streamStartTime + CLIFF_DURATION;
            tranches_[1].timestamp = streamStartTime + TOTAL_DURATION;
        }

        uint128 amount0 = ud(totalAmount).mul(ud(0.2e18)).intoUint128();
        uint128 amount1 = ud(totalAmount).mul(ud(0.8e18)).intoUint128();

        tranches_[0].amount = amount0;
        tranches_[1].amount = amount1;

        uint128 amountsSum = amount0 + amount1;

        if (amountsSum != totalAmount) {
            tranches_[1].amount += totalAmount - amountsSum;
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-VCA
    //////////////////////////////////////////////////////////////////////////*/

    function merkleVCAConstructorParams(
        address campaignOwner,
        uint40 expiration,
        bytes32 merkleRoot,
        MerkleVCA.Timestamps memory timestamps,
        IERC20 token_
    )
        public
        view
        returns (MerkleVCA.ConstructorParams memory)
    {
        return MerkleVCA.ConstructorParams({
            campaignName: CAMPAIGN_NAME,
            expiration: expiration,
            initialAdmin: campaignOwner,
            ipfsCID: IPFS_CID,
            merkleRoot: merkleRoot,
            timestamps: timestamps,
            token: token_
        });
    }

    function merkleVCATimestamps() public view returns (MerkleVCA.Timestamps memory) {
        return MerkleVCA.Timestamps({ start: RANGED_STREAM_START_TIME, end: RANGED_STREAM_END_TIME });
    }
}
