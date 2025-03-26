// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { MerkleVCA_Integration_Shared_Test } from "../MerkleVCA.t.sol";

contract CalculateForgoneAmount_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test {
    function test_WhenClaimTimeZero() external view {
        uint128 expectedForgoneAmount = VCA_FULL_AMOUNT - VCA_CLAIM_AMOUNT;

        // It should return the forgone amount.
        assertEq(merkleVCA.calculateForgoneAmount(VCA_FULL_AMOUNT, 0), expectedForgoneAmount, "forgone amount");
    }

    function test_WhenClaimTimeLessThanStartTime() external view whenClaimTimeNotZero {
        uint40 claimTime = VCA_START_TIME - 1;

        // It should return the full amount.
        assertEq(merkleVCA.calculateForgoneAmount(VCA_FULL_AMOUNT, claimTime), 0, "forgone amount");
    }

    function test_WhenClaimTimeEqualStartTime() external view whenClaimTimeNotZero {
        // It should return full vesting amount.
        assertEq(
            merkleVCA.calculateForgoneAmount(VCA_FULL_AMOUNT, VCA_START_TIME), VCA_VESTING_AMOUNT, "forgone amount"
        );
    }

    function test_WhenClaimTimeNotLessThanEndTime()
        external
        view
        whenClaimTimeNotZero
        whenClaimTimeGreaterThanStartTime
    {
        // It should return 0.
        assertEq(merkleVCA.calculateForgoneAmount(VCA_FULL_AMOUNT, VCA_END_TIME), 0, "forgone amount");
    }

    function test_WhenClaimTimeLessThanEndTime() external view whenClaimTimeNotZero whenClaimTimeGreaterThanStartTime {
        uint128 expectedForgoneAmount = VCA_FULL_AMOUNT - VCA_CLAIM_AMOUNT;

        // It should return the correct amount.
        assertEq(
            merkleVCA.calculateForgoneAmount(VCA_FULL_AMOUNT, getBlockTimestamp()),
            expectedForgoneAmount,
            "forgone amount"
        );
    }
}
