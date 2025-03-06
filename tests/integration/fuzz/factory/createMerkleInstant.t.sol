// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactoryInstant } from "src/interfaces/ISablierMerkleFactoryInstant.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { MerkleInstant } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract CreateMerkleInstant_Fuzz_Test is Integration_Test {
    function testFuzz_CreateMerkleInstant(
        address campaignOwner,
        uint256 customFee,
        bool enabled,
        uint40 expiration
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
            merkleFactoryInstant.setCustomFee(users.campaignCreator, customFee);
        }

        // Set campaign creator as the caller.
        resetPrank(users.campaignCreator);

        MerkleInstant.ConstructorParams memory params = merkleInstantConstructorParams(campaignOwner, expiration);

        // Get CREATE2 address of the campaign.
        address expectedMerkleInstant = computeMerkleInstantAddress(params, users.campaignCreator);

        // Expect a {CreateMerkleInstant} event.
        vm.expectEmit({ emitter: address(merkleFactoryInstant) });
        emit ISablierMerkleFactoryInstant.CreateMerkleInstant({
            merkleInstant: ISablierMerkleInstant(expectedMerkleInstant),
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            fee: enabled ? customFee : MINIMUM_FEE,
            oracle: address(oracle)
        });

        // Create the campaign.
        ISablierMerkleInstant actualMerkleInstant = createMerkleInstant(params);

        // Verify that the contract is deployed at the correct address.
        assertGt(address(actualMerkleInstant).code.length, 0, "MerkleInstant contract not created");
        assertEq(
            address(actualMerkleInstant),
            expectedMerkleInstant,
            "MerkleInstant contract does not match computed address"
        );

        // Verify the campaign's expiration state.
        bool isExpired = expiration > 0 && expiration <= block.timestamp ? true : false;
        assertEq(actualMerkleInstant.hasExpired(), isExpired, "isExpired");
    }
}
