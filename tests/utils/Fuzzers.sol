// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { MerkleLT } from "src/types/DataTypes.sol";

import { Modifiers } from "./Modifiers.sol";

abstract contract Fuzzers is Modifiers {
    // Fuzz tranches by making sure that total unlock percentage is 1e18 and total duration does not overflow the
    // maximum timestamp.
    function fuzzTranchesMerkleLT(
        uint40 startTime,
        MerkleLT.TrancheWithPercentage[] memory tranches
    )
        internal
        view
        returns (uint40 totalDuration)
    {
        uint256 upperBoundDuration;

        // Set upper bound based on the start time. A start time of 0 means block timestamp.
        if (startTime == 0) {
            upperBoundDuration = (MAX_UNIX_TIMESTAMP - getBlockTimestamp()) / tranches.length;
        } else {
            upperBoundDuration = (MAX_UNIX_TIMESTAMP - startTime) / tranches.length;
        }

        uint64 upperBoundPercentage = 1e18;

        for (uint256 i; i < tranches.length; ++i) {
            tranches[i].unlockPercentage =
                ud2x18(boundUint64(tranches[i].unlockPercentage.unwrap(), 0, upperBoundPercentage));
            tranches[i].duration = boundUint40(tranches[i].duration, 1, uint40(upperBoundDuration));

            totalDuration += tranches[i].duration;

            upperBoundPercentage -= tranches[i].unlockPercentage.unwrap();
        }

        // Add the remaining percentage to the last tranche.
        if (upperBoundPercentage > 0) {
            tranches[tranches.length - 1].unlockPercentage =
                ud2x18(tranches[tranches.length - 1].unlockPercentage.unwrap() + upperBoundPercentage);
        }
    }

    function getTotalDuration(MerkleLT.TrancheWithPercentage[] memory tranches)
        internal
        pure
        returns (uint40 totalDuration)
    {
        for (uint256 i; i < tranches.length; ++i) {
            totalDuration += tranches[i].duration;
        }
    }
}
