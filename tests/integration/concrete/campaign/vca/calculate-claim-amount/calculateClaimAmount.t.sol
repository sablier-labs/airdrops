// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { MerkleVCA_Integration_Shared_Test } from "../MerkleVCA.t.sol";

contract CalculateClaimAmount_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test {
    function test_WhenClaimTimeZero() external view {
        // It should return the claim amount.
        assertEq(merkleVCA.calculateClaimAmount(VCA_FULL_AMOUNT, 0), VCA_CLAIM_AMOUNT, "claim amount");
    }

    function test_WhenClaimTimeLessThanStartTime() external view whenClaimTimeNotZero {
        uint40 claimTime = VCA_START_TIME - 1;

        // It should return zero.
        assertEq(merkleVCA.calculateClaimAmount(VCA_FULL_AMOUNT, claimTime), 0, "claim amount");
    }

    function test_WhenClaimTimeEqualStartTime() external view whenClaimTimeNotZero {
        // It should return unlock amount.
        assertEq(merkleVCA.calculateClaimAmount(VCA_FULL_AMOUNT, VCA_START_TIME), VCA_UNLOCK_AMOUNT, "claim amount");
    }

    function test_WhenClaimTimeNotLessThanEndTime()
        external
        view
        whenClaimTimeNotZero
        whenClaimTimeGreaterThanStartTime
    {
        // It should return the full amount.
        assertEq(merkleVCA.calculateClaimAmount(VCA_FULL_AMOUNT, VCA_END_TIME), VCA_FULL_AMOUNT, "claim amount");
    }

    function test_WhenClaimTimeLessThanEndTime() external view whenClaimTimeNotZero whenClaimTimeGreaterThanStartTime {
        // It should return the claim amount.
        assertEq(merkleVCA.calculateClaimAmount(VCA_FULL_AMOUNT, getBlockTimestamp()), VCA_CLAIM_AMOUNT, "claim amount");
    }
}
