// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { UD2x18 } from "@prb/math/src/UD2x18.sol";
import { ISablierMerkleFactoryLT } from "src/interfaces/ISablierMerkleFactoryLT.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { MerkleLT } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract CreateMerkleLT_Fuzz_Test is Integration_Test {
    function testFuzz_CreateMerkleLT(
        address campaignOwner,
        uint256 customFee,
        bool enabled,
        uint40 expiration,
        uint40 streamStartTime,
        MerkleLT.TrancheWithPercentage[] memory tranches
    )
        external
        givenCampaignNotExists
    {
        // If enabled is true, set the custom fee.
        if (enabled) {
            // Bound the custom fee between 0 and MAX_FEE.
            customFee = bound(customFee, 0, MAX_FEE);

            // Enable the custom fee for this test.
            resetPrank(users.admin);
            merkleFactoryLT.setCustomFee(users.campaignCreator, customFee);
        }

        // Fuzz tranches to avoid overflow in total percentage.
        (uint256 expectedTotalDuration, uint64 expectedTotalPercentage) = fuzzTranchesLT(tranches);

        // Set campaign creator as the caller.
        resetPrank(users.campaignCreator);

        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams(campaignOwner, expiration);
        params.streamStartTime = streamStartTime;
        params.tranchesWithPercentages = tranches;

        // Get CREATE2 address of the campaign.
        address expectedMerkleLT = computeMerkleLTAddress(params, users.campaignCreator);

        // Expect a {CreateMerkleLT} event.
        vm.expectEmit({ emitter: address(merkleFactoryLT) });
        emit ISablierMerkleFactoryLT.CreateMerkleLT({
            merkleLT: ISablierMerkleLT(expectedMerkleLT),
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            totalDuration: expectedTotalDuration,
            fee: enabled ? customFee : MINIMUM_FEE,
            oracle: address(oracle)
        });

        // Create the campaign.
        ISablierMerkleLT actualMerkleLT = createMerkleLT(params);

        // Verify that the contract is deployed at the correct address.
        assertGt(address(actualMerkleLT).code.length, 0, "MerkleLT contract not created");
        assertEq(address(actualMerkleLT), expectedMerkleLT, "MerkleLT contract does not match computed address");

        // Verify the campaign's expiration state.
        bool isExpired = expiration > 0 && expiration <= block.timestamp ? true : false;
        assertEq(actualMerkleLT.hasExpired(), isExpired, "isExpired");

        // Verify that the campaign's tranches are correctly set.
        assertEq(actualMerkleLT.getTranchesWithPercentages(), tranches);
        assertEq(actualMerkleLT.STREAM_START_TIME(), streamStartTime, "stream start time");
        assertEq(actualMerkleLT.TOTAL_PERCENTAGE(), expectedTotalPercentage, "total percentage");
    }

    function fuzzTranchesLT(MerkleLT.TrancheWithPercentage[] memory tranches)
        internal
        pure
        returns (uint256 totalDuration, uint64 totalPercentage)
    {
        uint64 remainingPercentage = MAX_UINT64;

        for (uint256 i; i < tranches.length; ++i) {
            uint64 unlockPercentage = boundUint64(tranches[i].unlockPercentage.unwrap(), 0, remainingPercentage);
            tranches[i].unlockPercentage = UD2x18.wrap(unlockPercentage);

            // Use unchecked to mimic the logic from the contract, as overflow is permitted for total duration.
            unchecked {
                totalDuration += tranches[i].duration;
            }
            totalPercentage += unlockPercentage;
            remainingPercentage -= unlockPercentage;
        }

        return (totalDuration, totalPercentage);
    }
}
