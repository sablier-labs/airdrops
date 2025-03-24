// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { MerkleVCA_Integration_Shared_Test } from "../MerkleVCA.t.sol";

contract CalculateClaimAmount_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test {
    function test_WhenStartTimeInTheFuture() external {
        vm.warp({ newTimestamp: merkleVCA.getSchedule().startTime - 1 });
        assertEq(merkleVCA.calculateClaimAmount(CLAIM_AMOUNT), 0, "claim amount");
    }

    function test_WhenEndTimeInPast() external {
        vm.warp({ newTimestamp: RANGED_STREAM_END_TIME });
        assertEq(merkleVCA.calculateClaimAmount(CLAIM_AMOUNT), CLAIM_AMOUNT, "claim amount");
    }

    function test_WhenEndTimeNotInPast() external view {
        uint128 expectedClaimAmount = (CLAIM_AMOUNT * 2 days) / TOTAL_DURATION;
        assertEq(merkleVCA.calculateClaimAmount(CLAIM_AMOUNT), expectedClaimAmount, "claim amount");
    }
}
