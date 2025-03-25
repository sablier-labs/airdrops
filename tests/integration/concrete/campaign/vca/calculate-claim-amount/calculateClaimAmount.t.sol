// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { MerkleVCA_Integration_Shared_Test } from "../MerkleVCA.t.sol";

contract CalculateClaimAmount_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test {
    function test_WhenClaimTimeZero() external view {
        uint128 expectedClaimAmount = VCA_UNLOCK_AMOUNT + (VCA_VESTING_AMOUNT * 2 days) / TOTAL_DURATION;

        // It should return the claim amount.
        assertEq(merkleVCA.calculateClaimAmount(VCA_FULL_AMOUNT, 0), expectedClaimAmount, "claim amount");
    }

    function test_WhenClaimTimeLessThanStartTime() external view whenClaimTimeNotZero {
        uint40 claimTime = VCA_START_TIME - 1;

        // It should return zero.
        assertEq(merkleVCA.calculateClaimAmount(VCA_FULL_AMOUNT, claimTime), 0, "claim amount");
    }

    function test_WhenClaimTimeEqualStartTime() external view whenClaimTimeNotZero {
        uint40 claimTime = VCA_START_TIME;

        // It should return unlock amount.
        assertEq(merkleVCA.calculateClaimAmount(VCA_FULL_AMOUNT, claimTime), VCA_UNLOCK_AMOUNT, "claim amount");
    }

    function test_WhenClaimTimeNotLessThanEndTime()
        external
        view
        whenClaimTimeNotZero
        whenClaimTimeGreaterThanStartTime
    {
        uint40 claimTime = VESTING_END_TIME;

        // It should return the full amount.
        assertEq(merkleVCA.calculateClaimAmount(VCA_FULL_AMOUNT, claimTime), VCA_FULL_AMOUNT, "claim amount");
    }

    function test_WhenClaimTimeLessThanEndTime() external view whenClaimTimeNotZero whenClaimTimeGreaterThanStartTime {
        uint40 claimTime = getBlockTimestamp();

        uint128 expectedClaimAmount = VCA_UNLOCK_AMOUNT + (VCA_VESTING_AMOUNT * 2 days) / TOTAL_DURATION;

        // It should return the claim amount.
        assertEq(merkleVCA.calculateClaimAmount(VCA_FULL_AMOUNT, claimTime), expectedClaimAmount, "claim amount");
    }
}
