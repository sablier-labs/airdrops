// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactoryLL } from "src/interfaces/ISablierMerkleFactoryLL.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { MerkleLL } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract CreateMerkleLL_Fuzz_Test is Integration_Test {
    function testFuzz_CreateMerkleLL(
        address campaignOwner,
        uint256 customFee,
        bool enabled,
        uint40 expiration,
        MerkleLL.Schedule memory schedule
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
            merkleFactoryLL.setCustomFee(users.campaignCreator, customFee);
        }

        // Set campaign creator as the caller.
        resetPrank(users.campaignCreator);

        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams(campaignOwner, expiration);
        params.schedule = schedule;

        // Get CREATE2 address of the campaign.
        address expectedMerkleLL = computeMerkleLLAddress(params, users.campaignCreator);

        // Expect a {CreateMerkleLL} event.
        vm.expectEmit({ emitter: address(merkleFactoryLL) });
        emit ISablierMerkleFactoryLL.CreateMerkleLL({
            merkleLL: ISablierMerkleLL(expectedMerkleLL),
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            fee: enabled ? customFee : MINIMUM_FEE,
            oracle: address(oracle)
        });

        // Create the campaign.
        ISablierMerkleLL actualMerkleLL = createMerkleLL(params);

        // Verify that the contract is deployed at the correct address.
        assertGt(address(actualMerkleLL).code.length, 0, "MerkleLL contract not created");
        assertEq(address(actualMerkleLL), expectedMerkleLL, "MerkleLL contract does not match computed address");

        // Verify the campaign's expiration state.
        bool isExpired = expiration > 0 && expiration <= block.timestamp ? true : false;
        assertEq(actualMerkleLL.hasExpired(), isExpired, "isExpired");

        // Verify campaign's schedule.
        MerkleLL.Schedule memory actualSchedule = actualMerkleLL.getSchedule();
        assertEq(actualSchedule.startTime, schedule.startTime, "schedule.startTime");
        assertEq(actualSchedule.startPercentage, schedule.startPercentage, "schedule.startPercentage");
        assertEq(actualSchedule.cliffDuration, schedule.cliffDuration, "schedule.cliffDuration");
        assertEq(actualSchedule.cliffPercentage, schedule.cliffPercentage, "schedule.cliffPercentage");
        assertEq(actualSchedule.totalDuration, schedule.totalDuration, "schedule.totalDuration");
    }
}
