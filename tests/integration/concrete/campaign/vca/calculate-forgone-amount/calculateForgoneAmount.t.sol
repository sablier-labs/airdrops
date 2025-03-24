// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { MerkleVCA_Integration_Shared_Test } from "../MerkleVCA.t.sol";

contract CalculateForgoneAmount_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test {
    function test_WhenClaimTimeIs0() external {
        vm.warp({ newTimestamp: merkleVCA.getSchedule().startTime - 1 });
        assertEq(merkleVCA.calculateForgoneAmount(CLAIM_AMOUNT, 0), CLAIM_AMOUNT, "forgone amount");
    }

    function test_WhenStartTimeInFuture() external view whenClaimTimeNot0 {
        assertEq(
            merkleVCA.calculateForgoneAmount(CLAIM_AMOUNT, merkleVCA.getSchedule().startTime - 1),
            CLAIM_AMOUNT,
            "forgone amount"
        );
    }

    function test_WhenEndTimeInPast() external view whenClaimTimeNot0 whenStartTimeNotInFuture {
        assertEq(merkleVCA.calculateForgoneAmount(CLAIM_AMOUNT, RANGED_STREAM_END_TIME), 0, "forgone amount");
    }

    function test_WhenEndTimeNotInPast() external view whenClaimTimeNot0 whenStartTimeNotInFuture {
        uint128 expectedForgoneAmount = CLAIM_AMOUNT - ((CLAIM_AMOUNT * 2 days) / TOTAL_DURATION);
        assertEq(
            merkleVCA.calculateForgoneAmount(CLAIM_AMOUNT, getBlockTimestamp()), expectedForgoneAmount, "forgone amount"
        );
    }
}
