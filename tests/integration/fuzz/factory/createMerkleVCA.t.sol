// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactoryVCA } from "src/interfaces/ISablierMerkleFactoryVCA.sol";
import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { MerkleVCA } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract CreateMerkleVCA_Fuzz_Test is Integration_Test {
    function testFuzz_CreateMerkleVCA(
        address campaignOwner,
        uint256 customFee,
        bool enabled,
        uint40 expiration,
        MerkleVCA.Timestamps memory timestamps
    )
        external
        givenCampaignNotExists
        whenStartTimeNotZero
        whenEndTimeGreaterThanStartTime
        whenNotZeroExpiry
        whenExpiryNotExceedOneWeekFromEndTime
    {
        // Bound the timestamps and expiration to avoid any error.
        timestamps.end = boundUint40(timestamps.end, 2, MAX_UINT40 - 1 weeks);
        timestamps.start = boundUint40(timestamps.start, 1, timestamps.end - 1);
        expiration = boundUint40(expiration, timestamps.end + 1 weeks, MAX_UINT40);

        // If enabled is true, set the custom fee.
        if (enabled) {
            // Bound the custom fee between 0 and MAX_FEE.
            customFee = bound(customFee, 0, MAX_FEE);

            // Enable the custom fee for this test.
            resetPrank(users.admin);
            merkleFactoryVCA.setCustomFee(users.campaignCreator, customFee);
        }

        // Set campaign creator as the caller.
        resetPrank(users.campaignCreator);

        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams(campaignOwner, expiration);
        params.timestamps = timestamps;

        // Get CREATE2 address of the campaign.
        address expectedMerkleVCA = computeMerkleVCAAddress(params, users.campaignCreator);

        // Expect a {CreateMerkleVCA} event.
        vm.expectEmit({ emitter: address(merkleFactoryVCA) });
        emit ISablierMerkleFactoryVCA.CreateMerkleVCA({
            merkleVCA: ISablierMerkleVCA(expectedMerkleVCA),
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            fee: enabled ? customFee : MINIMUM_FEE,
            oracle: address(oracle)
        });

        // Create the campaign.
        ISablierMerkleVCA actualMerkleVCA = createMerkleVCA(params);

        // Verify that the contract is deployed at the correct address.
        assertGt(address(actualMerkleVCA).code.length, 0, "MerkleVCA contract not created");
        assertEq(address(actualMerkleVCA), expectedMerkleVCA, "MerkleVCA contract does not match computed address");

        // Verify the campaign's expiration state.
        bool isExpired = expiration <= block.timestamp ? true : false;
        assertEq(actualMerkleVCA.hasExpired(), isExpired, "isExpired");

        // Verify that the campaign's timestamps are correctly set.
        assertEq(actualMerkleVCA.timestamps().start, timestamps.start, "timestamps.start");
        assertEq(actualMerkleVCA.timestamps().end, timestamps.end, "timestamps.end");
    }
}
