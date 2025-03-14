// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactoryLT } from "src/interfaces/ISablierMerkleFactoryLT.sol";
import { ISablierMerkleLockup } from "src/interfaces/ISablierMerkleLockup.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";

import { MerkleLT } from "src/types/DataTypes.sol";

import { Shared_Fuzz_Test } from "./Fuzz.t.sol";

contract MerkleLT_Fuzz_Test is Shared_Fuzz_Test {
    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - Fuzzed custom fee.
    /// - MerkleLT campaign with fuzzed allocations, expiration, and tranches.
    /// - Both finite (only in future) and infinite expiration.
    /// - Claiming multiple airdrops with fuzzed claim fee at different point in time.
    /// - Fuzzed clawback amount.
    /// - Collect fees earned.
    function testFuzz_MerkleLT(
        Allocation[] memory allocation,
        uint128 clawbackAmount,
        uint256 feeForUser,
        bool enableCustomFee,
        uint40 expiration,
        uint256[] memory indexesToClaim,
        uint256 msgValue,
        uint40 startTime,
        MerkleLT.TrancheWithPercentage[] memory tranches
    )
        external
    {
        // Ensure that merkle data is not empty.
        vm.assume(allocation.length > 0 && indexesToClaim.length < allocation.length);

        // Ensure that tranches are not empty and not too large.
        vm.assume(tranches.length <= 1000 && tranches.length > 0);

        // Bound expiration so that the campaign is still active at the block time.
        if (expiration > 0) expiration = boundUint40(expiration, getBlockTimestamp() + 365 days, MAX_UNIX_TIMESTAMP);

        // Set the custom fee if enabled.
        feeForUser = enableCustomFee ? testSetCustomFee(merkleFactoryLT, feeForUser) : MINIMUM_FEE;

        // Construct merkle root for the given allocation data.
        (uint256 aggregateAmount, bytes32 merkleRoot) = constructMerkleTree(allocation);

        // Bound the start time.
        startTime = boundUint40(startTime, 0, getBlockTimestamp() + 1000);

        uint40 streamDuration = fuzzTranchesMerkleLT(startTime, tranches);

        // Test creating the MerkleLT campaign.
        _testCreateMerkleLT(aggregateAmount, expiration, feeForUser, merkleRoot, startTime, streamDuration, tranches);

        // Test claiming the airdrop for the given indexes.
        testClaimMultipleAirdrops(merkleLT, indexesToClaim, msgValue);

        // Test clawbacking funds.
        testClawback(merkleLT, clawbackAmount);

        // Test collecting fees earned.
        testCollectFees(merkleFactoryLT, merkleLT);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CREATE-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function _testCreateMerkleLT(
        uint256 aggregateAmount,
        uint40 expiration,
        uint256 feeForUser,
        bytes32 merkleRoot,
        uint40 startTime,
        uint40 streamDuration,
        MerkleLT.TrancheWithPercentage[] memory tranches
    )
        private
        givenCampaignNotExists
        whenTotalPercentage100
    {
        // Set campaign creator as the caller.
        resetPrank(users.campaignCreator);

        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams(expiration);
        params.merkleRoot = merkleRoot;
        params.streamStartTime = startTime;
        params.tranchesWithPercentages = tranches;

        // Precompute the deterministic address.
        address expectedMerkleLT = computeMerkleLTAddress(params, users.campaignCreator);

        // Expect a {CreateMerkleLT} event.
        vm.expectEmit({ emitter: address(merkleFactoryLT) });
        emit ISablierMerkleFactoryLT.CreateMerkleLT({
            merkleLT: ISablierMerkleLT(expectedMerkleLT),
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: allotment.length,
            totalDuration: streamDuration,
            fee: feeForUser,
            oracle: address(oracle)
        });

        // Create the campaign.
        merkleLT = merkleFactoryLT.createMerkleLT(params, aggregateAmount, allotment.length);

        // It should deploy the contract at the correct address.
        assertGt(address(merkleLT).code.length, 0, "MerkleLT contract not created");
        assertEq(address(merkleLT), expectedMerkleLT, "MerkleLT contract does not match computed address");

        // It should return false for hasExpired.
        assertFalse(merkleLT.hasExpired(), "isExpired");

        // It should return the correct schedule tranches.
        assertEq(merkleLT.getTranchesWithPercentages(), tranches);
        assertEq(merkleLT.STREAM_START_TIME(), startTime);
        assertEq(merkleLT.TOTAL_PERCENTAGE(), 1e18);

        // Fund the MerkleLT contract.
        deal({ token: address(dai), to: address(merkleLT), give: aggregateAmount });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CLAIM-EVENT-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function expectClaimEvent(Allocation memory allocation) internal override {
        uint40 totalDuration = getTotalDuration(merkleLT.getTranchesWithPercentages());

        // Calculate end time based on the start time.
        uint40 startTime = merkleLT.STREAM_START_TIME();
        uint40 endTime = startTime == 0 ? getBlockTimestamp() + totalDuration : startTime + totalDuration;

        // If the vesting has ended, the claim should be transferred directly to the recipient.
        if (endTime <= getBlockTimestamp()) {
            vm.expectEmit({ emitter: address(merkleLT) });
            emit ISablierMerkleLockup.Claim(allocation.index, allocation.recipient, allocation.amount);

            expectCallToTransfer({ token: dai, to: allocation.recipient, value: allocation.amount });
        }
        // Otherwise, the claim should be transferred to the lockup contract.
        else {
            uint256 expectedStreamId = lockup.nextStreamId();
            vm.expectEmit({ emitter: address(merkleLT) });
            emit ISablierMerkleLockup.Claim(allocation.index, allocation.recipient, allocation.amount, expectedStreamId);

            expectCallToTransferFrom({
                token: dai,
                from: address(merkleLT),
                to: address(lockup),
                value: allocation.amount
            });
        }
    }
}
