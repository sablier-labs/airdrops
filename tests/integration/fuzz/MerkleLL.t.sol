// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud2x18 } from "@prb/math/src/UD2x18.sol";

import { ISablierMerkleFactoryLL } from "src/interfaces/ISablierMerkleFactoryLL.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLockup } from "src/interfaces/ISablierMerkleLockup.sol";

import { MerkleLL } from "src/types/DataTypes.sol";

import { Shared_Fuzz_Test } from "./Fuzz.t.sol";

contract MerkleLL_Fuzz_Test is Shared_Fuzz_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                        TEST
    //////////////////////////////////////////////////////////////////////////*/

    function testFuzz_MerkleLL(
        Allocation[] memory allocation,
        uint128 clawbackAmount,
        uint256 feeForUser,
        bool enabled,
        uint40 expiration,
        uint256[] memory indexesToClaim,
        uint256 msgValue,
        MerkleLL.Schedule memory schedule,
        uint40 timeJumpSeed
    )
        external
    {
        // Ensure that merkle data is not empty.
        vm.assume(allocation.length > 0 && indexesToClaim.length < allocation.length);

        // Set the custom fee if enabled.
        feeForUser = enabled ? setCustomFee(merkleFactoryLL, feeForUser) : MINIMUM_FEE;

        // Generate merkle root for the given allocation data.
        (uint256 aggregateAmount, bytes32 merkleRoot) = generateMerkleRoot(allocation);

        // Create the MerkleLL campaign.
        _createMerkleLL(aggregateAmount, expiration, feeForUser, merkleRoot, schedule);

        firstClaimTime = getBlockTimestamp();

        // Claim the airdrop for the given indexes.
        _claimAirdrops(indexesToClaim, msgValue, timeJumpSeed);

        // Clawback funds.
        clawback(merkleLL, clawbackAmount);

        // Collect fees earned.
        collectFee(merkleFactoryLL, merkleLL);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CREATE-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function _createMerkleLL(
        uint256 aggregateAmount,
        uint40 expiration,
        uint256 feeForUser,
        bytes32 merkleRoot,
        MerkleLL.Schedule memory schedule
    )
        private
        givenCampaignNotExists
        whenTotalPercentageNotGreaterThan100
    {
        // Bound expiration so that the campaign is still active at the block time.
        if (expiration > 0) expiration = boundUint40(expiration, getBlockTimestamp() + 365 days, MAX_UNIX_TIMESTAMP);

        // Bound the start time.
        schedule.startTime = boundUint40(schedule.startTime, 0, MAX_UNIX_TIMESTAMP - 1);

        // Expected start time is the start time if it is set, otherwise the current block time.
        uint40 expectedStartTime = schedule.startTime == 0 ? getBlockTimestamp() : schedule.startTime;

        // Bound cliff duration so that it does not overflow timestamps.
        schedule.cliffDuration = boundUint40(schedule.cliffDuration, 0, MAX_UNIX_TIMESTAMP - expectedStartTime - 1);

        // Bound the total duration so that the end time to be greater than the cliff time.
        schedule.totalDuration =
            boundUint40(schedule.totalDuration, schedule.cliffDuration + 1, MAX_UNIX_TIMESTAMP - expectedStartTime);

        // Bound unlock percentages so that the sum does not exceed 100%.
        schedule.startPercentage = _bound(schedule.startPercentage, 0, 1e18);

        // Bound cliff percentage so that the sum does not exceed 100% and is 0 if cliff duration is 0.
        schedule.cliffPercentage = schedule.cliffDuration > 0
            ? _bound(schedule.cliffPercentage, 0, 1e18 - schedule.startPercentage.unwrap())
            : ud2x18(0);

        // Set campaign creator as the caller.
        resetPrank(users.campaignCreator);

        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams(users.campaignCreator, expiration);
        params.schedule = schedule;
        params.merkleRoot = merkleRoot;

        // Get CREATE2 address of the campaign.
        address expectedMerkleLL = computeMerkleLLAddress(params, users.campaignCreator);

        // Expect a {CreateMerkleLL} event.
        vm.expectEmit({ emitter: address(merkleFactoryLL) });
        emit ISablierMerkleFactoryLL.CreateMerkleLL({
            merkleLL: ISablierMerkleLL(expectedMerkleLL),
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: allotment.length,
            fee: feeForUser,
            oracle: address(oracle)
        });

        // Create the campaign.
        merkleLL = merkleFactoryLL.createMerkleLL(params, aggregateAmount, allotment.length);

        // Verify that the contract is deployed at the correct address.
        assertGt(address(merkleLL).code.length, 0, "MerkleLL contract not created");
        assertEq(address(merkleLL), expectedMerkleLL, "MerkleLL contract does not match computed address");

        // Verify the campaign's expiration state.
        bool isExpired = expiration > 0 && expiration <= block.timestamp ? true : false;
        assertEq(merkleLL.hasExpired(), isExpired, "isExpired");

        // Verify campaign's schedule.
        assertEq(merkleLL.getSchedule(), schedule);

        // Fund the MerkleLL contract.
        deal({ token: address(dai), to: address(merkleLL), give: aggregateAmount });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CLAIM-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function _claimAirdrops(
        uint256[] memory indexesToClaim,
        uint256 msgValue,
        uint40 timeJumpSeed
    )
        private
        givenMsgValueNotLessThanFee
    {
        for (uint256 i; i < indexesToClaim.length; ++i) {
            // Bound lead index so its valid.
            uint256 leafIndex = bound(indexesToClaim[i], 0, allotment.length - 1);

            // Claim the airdrop if it has not been claimed.
            if (!merkleLL.hasClaimed(allotment[leafIndex].index)) {
                // Bound msgValue so that its greater than the minimum fee.
                msgValue = bound(msgValue, merkleLL.minimumFeeInWei(), 100 ether);

                resetPrank(users.recipient);
                vm.deal(users.recipient, msgValue);

                Allocation memory allocation = allotment[leafIndex];

                // It should emit {Claim} event based on the vesting end time.
                MerkleLL.Schedule memory schedule = merkleLL.getSchedule();
                uint40 expectedStartTime = schedule.startTime == 0 ? getBlockTimestamp() : schedule.startTime;

                // If the vesting has ended, the claim should be transferred directly to the recipient.
                if (expectedStartTime + schedule.totalDuration <= getBlockTimestamp()) {
                    vm.expectEmit({ emitter: address(merkleLL) });
                    emit ISablierMerkleLockup.Claim(allocation.index, allocation.recipient, allocation.amount);

                    expectCallToTransfer({ token: dai, to: allocation.recipient, value: allocation.amount });
                }
                // Otherwise, the claim should be transferred to the lockup contract.
                else {
                    uint256 expectedStreamId = lockup.nextStreamId();
                    vm.expectEmit({ emitter: address(merkleLL) });
                    emit ISablierMerkleLockup.Claim(
                        allocation.index, allocation.recipient, allocation.amount, expectedStreamId
                    );

                    expectCallToTransferFrom({
                        token: dai,
                        from: address(merkleLL),
                        to: address(lockup),
                        value: allocation.amount
                    });
                }

                bytes32[] memory merkleProof = computerMerkleProof(allocation);

                // Claim the airdrop.
                merkleLL.claim{ value: msgValue }({
                    index: allocation.index,
                    recipient: allocation.recipient,
                    amount: allocation.amount,
                    merkleProof: merkleProof
                });

                // Assert that the claim has been made.
                assertTrue(merkleLL.hasClaimed(allocation.index));

                // Update the fee earned.
                feeEarned += msgValue;

                // Warp to a new time.
                timeJumpSeed = boundUint40(timeJumpSeed, 0, 7 days);
                vm.warp(getBlockTimestamp() + timeJumpSeed);

                // Break loop if the campaign has expired.
                if (merkleLL.EXPIRATION() > 0 && getBlockTimestamp() >= merkleLL.EXPIRATION()) {
                    break;
                }
            }
        }
    }
}
