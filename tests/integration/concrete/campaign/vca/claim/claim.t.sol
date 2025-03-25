// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Claim_Integration_Test } from "../../shared/claim/claim.t.sol";
import { MerkleVCA_Integration_Shared_Test, Integration_Test } from "../MerkleVCA.t.sol";

contract Claim_MerkleVCA_Integration_Test is Claim_Integration_Test, MerkleVCA_Integration_Shared_Test {
    function setUp() public virtual override(MerkleVCA_Integration_Shared_Test, Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_StartTimeInFuture() external whenMerkleProofValid {
        // Move back in time so that the start time is in the future.
        vm.warp({ newTimestamp: VCA_START_TIME - 1 seconds });

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleVCA_CampaignNotStarted.selector, VCA_START_TIME));

        // Claim the airdrop.
        merkleVCA.claim{ value: MIN_FEE_WEI }({
            index: 1,
            recipient: users.recipient1,
            amount: VCA_FULL_AMOUNT,
            merkleProof: index1Proof()
        });
    }

    function test_WhenStartTimeInPresent() external whenMerkleProofValid whenStartTimeNotInFuture {
        // Forward in time so that the end time is in the past.
        vm.warp({ newTimestamp: VCA_START_TIME });

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.Claim({
            index: INDEX1,
            recipient: users.recipient1,
            claimAmount: VCA_UNLOCK_AMOUNT,
            forgoneAmount: VCA_VESTING_AMOUNT
        });

        // It should transfer the unlock amount.
        expectCallToTransfer({ to: users.recipient1, value: VCA_UNLOCK_AMOUNT });
        expectCallToClaimWithMsgValue(address(merkleVCA), MIN_FEE_WEI);

        merkleVCA.claim{ value: MIN_FEE_WEI }({
            index: 1,
            recipient: users.recipient1,
            amount: VCA_FULL_AMOUNT,
            merkleProof: index1Proof()
        });

        // It should update the claimed status.
        assertTrue(merkleVCA.hasClaimed(INDEX1), "not claimed");

        // It should update the total forgone amount.
        assertEq(merkleVCA.totalForgoneAmount(), VCA_VESTING_AMOUNT, "total forgone amount");
    }

    function test_WhenEndTimeInPast() external whenMerkleProofValid whenStartTimeNotInFuture {
        // Forward in time so that the end time is in the past.
        vm.warp({ newTimestamp: VCA_END_TIME });

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.Claim({
            index: INDEX1,
            recipient: users.recipient1,
            claimAmount: VCA_FULL_AMOUNT,
            forgoneAmount: 0
        });

        // It should transfer the full amount.
        expectCallToTransfer({ to: users.recipient1, value: VCA_FULL_AMOUNT });
        expectCallToClaimWithMsgValue(address(merkleVCA), MIN_FEE_WEI);

        merkleVCA.claim{ value: MIN_FEE_WEI }({
            index: 1,
            recipient: users.recipient1,
            amount: VCA_FULL_AMOUNT,
            merkleProof: index1Proof()
        });

        // It should update the claimed status.
        assertTrue(merkleVCA.hasClaimed(INDEX1), "not claimed");

        // It should not update the total forgone amount.
        assertEq(merkleVCA.totalForgoneAmount(), 0, "total forgone amount");
    }

    function test_WhenEndTimeNotInPast() external whenMerkleProofValid whenStartTimeNotInFuture {
        uint128 claimAmount = VCA_UNLOCK_AMOUNT + (VCA_VESTING_AMOUNT * 2 days) / TOTAL_DURATION;
        uint128 forgoneAmount = VCA_FULL_AMOUNT - claimAmount;

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.Claim({
            index: INDEX1,
            recipient: users.recipient1,
            claimAmount: claimAmount,
            forgoneAmount: forgoneAmount
        });

        // It should transfer a portion of the amount.
        expectCallToTransfer({ to: users.recipient1, value: claimAmount });
        expectCallToClaimWithMsgValue(address(merkleVCA), MIN_FEE_WEI);

        merkleVCA.claim{ value: MIN_FEE_WEI }({
            index: 1,
            recipient: users.recipient1,
            amount: VCA_FULL_AMOUNT,
            merkleProof: index1Proof()
        });

        // It should update the claimed status.
        assertTrue(merkleVCA.hasClaimed(INDEX1), "not claimed");

        // It should update the total forgone amount.
        assertEq(merkleVCA.totalForgoneAmount(), forgoneAmount, "total forgone amount");
    }
}
