// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactoryLT } from "src/interfaces/ISablierMerkleFactoryLT.sol";
import { ISablierMerkleLockup } from "src/interfaces/ISablierMerkleLockup.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";

import { MerkleLT } from "src/types/DataTypes.sol";

import { Shared_Fuzz_Test } from "./Fuzz.t.sol";

contract MerkleLT_Fuzz_Test is Shared_Fuzz_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                        TEST
    //////////////////////////////////////////////////////////////////////////*/

    function testFuzz_MerkleLT(
        Allocation[] memory allocation,
        uint128 clawbackAmount,
        uint256 feeForUser,
        bool enabled,
        uint40 expiration,
        uint256[] memory indexesToClaim,
        uint256 msgValue,
        uint40 startTime,
        uint40 timeJumpSeed,
        MerkleLT.TrancheWithPercentage[] memory tranches
    )
        external
    {
        // Ensure that merkle data is not empty.
        vm.assume(allocation.length > 0 && indexesToClaim.length < allocation.length);

        // Ensure that tranches are not empty and not too large.
        vm.assume(tranches.length <= 1000 && tranches.length > 0);

        // Set the custom fee if enabled.
        feeForUser = enabled ? setCustomFee(merkleFactoryLT, feeForUser) : MINIMUM_FEE;

        // Generate merkle root for the given allocation data.
        (uint256 aggregateAmount, bytes32 merkleRoot) = generateMerkleRoot(allocation);

        // Bound the start time.
        startTime = boundUint40(startTime, 0, MAX_UNIX_TIMESTAMP - 1000);

        uint40 streamDuration = fuzzTranchesMerkleLT(startTime, tranches);

        // Create the MerkleLT campaign.
        _createMerkleLT(aggregateAmount, expiration, feeForUser, merkleRoot, startTime, streamDuration, tranches);

        firstClaimTime = getBlockTimestamp();

        // Claim the airdrop for the given indexes.
        _claimAirdrops(indexesToClaim, msgValue, timeJumpSeed, streamDuration, startTime);

        // Clawback funds.
        clawback(merkleLT, clawbackAmount);

        // Collect fees earned.
        collectFee(merkleFactoryLT, merkleLT);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CREATE-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function _createMerkleLT(
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
        // Bound expiration so that the campaign is still active at the block time.
        if (expiration > 0) expiration = boundUint40(expiration, getBlockTimestamp() + 365 days, MAX_UNIX_TIMESTAMP);

        // Set campaign creator as the caller.
        resetPrank(users.campaignCreator);

        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams(users.campaignCreator, expiration);
        params.merkleRoot = merkleRoot;
        params.streamStartTime = startTime;
        params.tranchesWithPercentages = tranches;

        // Get CREATE2 address of the campaign.
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

        // Verify that the contract is deployed at the correct address.
        assertGt(address(merkleLT).code.length, 0, "MerkleLT contract not created");
        assertEq(address(merkleLT), expectedMerkleLT, "MerkleLT contract does not match computed address");

        // Verify the campaign's expiration state.
        bool isExpired = expiration > 0 && expiration <= getBlockTimestamp() ? true : false;
        assertEq(merkleLT.hasExpired(), isExpired, "isExpired");

        // Verify tranches.
        assertEq(merkleLT.getTranchesWithPercentages(), tranches);

        // Fund the MerkleLT contract.
        deal({ token: address(dai), to: address(merkleLT), give: aggregateAmount });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CLAIM-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function _claimAirdrops(
        uint256[] memory indexesToClaim,
        uint256 msgValue,
        uint40 timeJumpSeed,
        uint40 streamDuration,
        uint40 startTime
    )
        private
        givenMsgValueNotLessThanFee
        whenTotalPercentage100
    {
        for (uint256 i; i < indexesToClaim.length; ++i) {
            // Bound lead index so its valid.
            uint256 leafIndex = bound(indexesToClaim[i], 0, allotment.length - 1);

            // Claim the airdrop if it has not been claimed.
            if (!merkleLT.hasClaimed(allotment[leafIndex].index)) {
                // Bound msgValue so that its greater than the minimum fee.
                msgValue = bound(msgValue, merkleLT.minimumFeeInWei(), 100 ether);

                resetPrank(users.recipient);
                vm.deal(users.recipient, msgValue);

                Allocation memory allocation = allotment[leafIndex];

                // Calculate end time based on the start time.
                uint40 endTime;
                if (startTime == 0) {
                    endTime = getBlockTimestamp() + streamDuration;
                } else {
                    endTime = startTime + streamDuration;
                }

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
                    emit ISablierMerkleLockup.Claim(
                        allocation.index, allocation.recipient, allocation.amount, expectedStreamId
                    );

                    expectCallToTransferFrom({
                        token: dai,
                        from: address(merkleLT),
                        to: address(lockup),
                        value: allocation.amount
                    });
                }

                bytes32[] memory merkleProof = computerMerkleProof(allocation);

                // Claim the airdrop.
                merkleLT.claim{ value: msgValue }({
                    index: allocation.index,
                    recipient: allocation.recipient,
                    amount: allocation.amount,
                    merkleProof: merkleProof
                });

                // Assert that the claim has been made.
                assertTrue(merkleLT.hasClaimed(allocation.index));

                // Update the fee earned.
                feeEarned += msgValue;

                // Warp to a new time.
                timeJumpSeed = boundUint40(timeJumpSeed, 0, 7 days);
                vm.warp(getBlockTimestamp() + timeJumpSeed);

                // Break loop if the campaign has expired.
                if (merkleLT.EXPIRATION() > 0 && getBlockTimestamp() >= merkleLT.EXPIRATION()) {
                    break;
                }
            }
        }
    }
}
