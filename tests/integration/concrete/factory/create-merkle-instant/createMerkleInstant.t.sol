// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactory } from "src/interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { MerkleInstant } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract CreateMerkleInstant_Integration_Test is Integration_Test {
    /// @dev This test works because a default MerkleInstant contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CampaignAlreadyExists() external {
        MerkleInstant.CreateParams memory createParams = merkleInstantCreateParams();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        merkleFactory.createMerkleInstant(createParams);
    }

    function test_GivenCustomFeeSet(
        address campaignOwner,
        uint40 expiration,
        uint256 customFee
    )
        external
        givenCampaignNotExists
    {
        // Set the custom fee to 0 for this test.
        resetPrank(users.admin);
        merkleFactory.setCustomFee(users.campaignOwner, customFee);

        resetPrank(users.campaignOwner);
        address expectedMerkleInstant = computeMerkleInstantAddress(campaignOwner, expiration);

        // It should emit a {CreateMerkleInstant} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.CreateMerkleInstant({
            merkleInstant: ISablierMerkleInstant(expectedMerkleInstant),
            createParams: merkleInstantCreateParams(campaignOwner, expiration),
            fee: customFee
        });

        ISablierMerkleInstant actualInstant = createMerkleInstant(campaignOwner, expiration);
        assertGt(address(actualInstant).code.length, 0, "MerkleInstant contract not created");
        assertEq(
            address(actualInstant), expectedMerkleInstant, "MerkleInstant contract does not match computed address"
        );

        // It should create the campaign with custom fee.
        assertEq(actualInstant.FEE(), customFee, "fee");

        // It should set the current factory address.
        assertEq(actualInstant.FACTORY(), address(merkleFactory), "factory");
    }

    function test_GivenCustomFeeNotSet(address campaignOwner, uint40 expiration) external givenCampaignNotExists {
        address expectedMerkleInstant = computeMerkleInstantAddress(campaignOwner, expiration);

        // It should emit a {CreateMerkleInstant} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.CreateMerkleInstant({
            merkleInstant: ISablierMerkleInstant(expectedMerkleInstant),
            createParams: merkleInstantCreateParams(campaignOwner, expiration),
            fee: defaults.FEE()
        });

        ISablierMerkleInstant actualInstant = createMerkleInstant(campaignOwner, expiration);
        assertGt(address(actualInstant).code.length, 0, "MerkleInstant contract not created");
        assertEq(
            address(actualInstant), expectedMerkleInstant, "MerkleInstant contract does not match computed address"
        );

        // It should create the campaign with custom fee.
        assertEq(actualInstant.FEE(), defaults.FEE(), "default fee");

        // It should set the current factory address.
        assertEq(actualInstant.FACTORY(), address(merkleFactory), "factory");
    }
}
