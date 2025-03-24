// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { MerkleVCA_Integration_Shared_Test } from "../MerkleVCA.t.sol";

contract CalculateClaimAmount_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test {
    function test_WhenClaimTimeIs0() external {
        uint40 claimTime = 0;
        vm.warp({ newTimestamp: merkleVCA.getSchedule().startTime - 1 });
        assertEq(merkleVCA.calculateClaimAmount(CLAIM_AMOUNT, claimTime), 0, "claim amount");
    }

    function test_WhenStartTimeInFuture() external view whenClaimTimeNot0 {
        assertEq(merkleVCA.calculateClaimAmount(CLAIM_AMOUNT, merkleVCA.getSchedule().startTime - 1), 0, "claim amount");
    }

    function test_WhenEndTimeInPast() external view whenClaimTimeNot0 whenStartTimeNotInFuture {
        assertEq(merkleVCA.calculateClaimAmount(CLAIM_AMOUNT, RANGED_STREAM_END_TIME), CLAIM_AMOUNT, "claim amount");
    }

    function test_WhenEndTimeNotInPast() external view whenClaimTimeNot0 whenStartTimeNotInFuture {
        uint128 expectedClaimAmount = (CLAIM_AMOUNT * 2 days) / TOTAL_DURATION;
        assertEq(merkleVCA.calculateClaimAmount(CLAIM_AMOUNT, getBlockTimestamp()), expectedClaimAmount, "claim amount");
    }
}
