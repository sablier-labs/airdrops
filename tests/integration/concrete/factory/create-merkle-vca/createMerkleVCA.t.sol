// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactory } from "src/interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleVCA } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../Integration.t.sol";

/// @dev Some of the tests use `users.sender` as the campaign owner to avoid collision with the default MerkleVCA
/// contract deployed in {Integration_Test.setUp}.
contract CreateMerkleVCA_Integration_Test is Integration_Test {
    /// @dev This test reverts because a default MerkleVCA contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CampaignAlreadyExists() external {
        // This test fails
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        merkleFactory.createMerkleVCA({
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT
        });
    }

    function test_RevertWhen_StartTimeZero() external givenCampaignNotExists {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.timestamps.start = 0;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleVCA_UnlockTimeZero.selector, 0, params.timestamps.end)
        );
        merkleFactory.createMerkleVCA({
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT
        });
    }

    function test_RevertWhen_EndTimeZero() external givenCampaignNotExists {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.timestamps.end = 0;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleVCA_UnlockTimeZero.selector, params.timestamps.start, 0)
        );
        merkleFactory.createMerkleVCA({
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT
        });
    }

    function test_RevertWhen_EndTimeLessThanStartTime()
        external
        givenCampaignNotExists
        whenStartTimeNotZero
        whenEndTimeNotZero
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        // Set the end time to be less than the start time.
        params.timestamps.end = RANGED_STREAM_START_TIME - 1;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleVCA_StartTimeExceedsEndTime.selector, params.timestamps.start, params.timestamps.end
            )
        );
        merkleFactory.createMerkleVCA({
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT
        });
    }

    function test_RevertWhen_EndTimeEqualsStartTime()
        external
        givenCampaignNotExists
        whenStartTimeNotZero
        whenEndTimeNotZero
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        // Set the end time equal to the start time.
        params.timestamps.end = defaults.RANGED_STREAM_START_TIME();

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleVCA_StartTimeExceedsEndTime.selector, params.timestamps.start, params.timestamps.end
            )
        );
        merkleFactory.createMerkleVCA({
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT
        });
    }

    function test_WhenZeroExpiry()
        external
        givenCampaignNotExists
        whenStartTimeNotZero
        whenEndTimeNotZero
        whenEndTimeGreaterThanStartTime
    {
        address expectedMerkleVCA = computeMerkleVCAAddress({ campaignOwner: users.sender, expiration: 0 });

        // It should emit a {CreateMerkleVCA} event.
        vm.expectEmit(address(merkleFactory));
        emit ISablierMerkleFactory.CreateMerkleVCA({
            merkleVCA: ISablierMerkleVCA(address(expectedMerkleVCA)),
            params: merkleVCAConstructorParams({ campaignOwner: users.sender, expiration: 0 }),
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            fee: MINIMUM_FEE
        });

        ISablierMerkleVCA actualVCA = createMerkleVCA({ campaignOwner: users.sender, expiration: 0 });

        // It should create the campaign with custom fee.
        assertEq(actualVCA.MINIMUM_FEE(), MINIMUM_FEE, "minimum fee");

        // It should set the current factory address.
        assertEq(actualVCA.FACTORY(), address(merkleFactory), "factory");

        // It should set the expiry to 0.
        assertEq(actualVCA.EXPIRATION(), 0, "expiration");

        // It should set return the correct unlock schedule.
        assertEq(actualVCA.timestamps().start, RANGED_STREAM_START_TIME, "unlock start");
        assertEq(actualVCA.timestamps().end, RANGED_STREAM_END_TIME, "unlock end");
    }

    function test_RevertWhen_ExpiryNotExceedOneWeekFromEndTime()
        external
        givenCampaignNotExists
        whenStartTimeNotZero
        whenEndTimeNotZero
        whenEndTimeGreaterThanStartTime
        whenNotZeroExpiry
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.expiration = RANGED_STREAM_END_TIME + 1 weeks - 1;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleVCA_ExpiryWithinOneWeekOfUnlockEndTime.selector,
                params.timestamps.end,
                params.expiration
            )
        );
        merkleFactory.createMerkleVCA(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);
    }

    function test_GivenCustomFeeSet()
        external
        givenCampaignNotExists
        whenStartTimeNotZero
        whenEndTimeNotZero
        whenEndTimeGreaterThanStartTime
        whenNotZeroExpiry
        whenExpiryNotExceedOneWeekFromEndTime
    {
        // Set the custom fee to 0 for this test.
        resetPrank(users.admin);
        merkleFactory.setCustomFee(users.campaignOwner, 0);

        resetPrank(users.campaignOwner);
        address expectedMerkleVCA = computeMerkleVCAAddress({ campaignOwner: users.sender, expiration: EXPIRATION });

        // It should emit a {CreateMerkleVCA} event.
        vm.expectEmit(address(merkleFactory));
        emit ISablierMerkleFactory.CreateMerkleVCA({
            merkleVCA: ISablierMerkleVCA(address(expectedMerkleVCA)),
            params: merkleVCAConstructorParams({ campaignOwner: users.sender, expiration: EXPIRATION }),
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            fee: 0
        });

        ISablierMerkleVCA actualVCA = createMerkleVCA({ campaignOwner: users.sender, expiration: EXPIRATION });
        assertGt(address(actualVCA).code.length, 0, "MerkleVCA contract not created");
        assertEq(address(actualVCA), expectedMerkleVCA, "MerkleVCA contract does not match computed address");

        // It should create the campaign with 0 custom fee.
        assertEq(actualVCA.MINIMUM_FEE(), 0, "custom fee");

        // It should set the current factory address.
        assertEq(actualVCA.FACTORY(), address(merkleFactory), "factory");

        // It should set return the correct unlock schedule.
        assertEq(actualVCA.timestamps().start, RANGED_STREAM_START_TIME, "unlock start");
        assertEq(actualVCA.timestamps().end, RANGED_STREAM_END_TIME, "unlock end");
    }

    function test_GivenCustomFeeNotSet()
        external
        givenCampaignNotExists
        whenStartTimeNotZero
        whenEndTimeNotZero
        whenEndTimeGreaterThanStartTime
        whenNotZeroExpiry
        whenExpiryNotExceedOneWeekFromEndTime
    {
        address expectedMerkleVCA = computeMerkleVCAAddress({ campaignOwner: users.sender, expiration: EXPIRATION });

        // It should emit a {CreateMerkleVCA} event.
        vm.expectEmit(address(merkleFactory));
        emit ISablierMerkleFactory.CreateMerkleVCA({
            merkleVCA: ISablierMerkleVCA(address(expectedMerkleVCA)),
            params: merkleVCAConstructorParams({ campaignOwner: users.sender, expiration: EXPIRATION }),
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            fee: MINIMUM_FEE
        });

        ISablierMerkleVCA actualVCA = createMerkleVCA({ campaignOwner: users.sender, expiration: EXPIRATION });
        assertGt(address(actualVCA).code.length, 0, "MerkleVCA contract not created");
        assertEq(address(actualVCA), expectedMerkleVCA, "MerkleVCA contract does not match computed address");

        // It should create the campaign with custom fee.
        assertEq(actualVCA.MINIMUM_FEE(), MINIMUM_FEE, "minimum fee");

        // It should set the current factory address.
        assertEq(actualVCA.FACTORY(), address(merkleFactory), "factory");

        // It should set return the correct unlock schedule.
        assertEq(actualVCA.timestamps().start, RANGED_STREAM_START_TIME, "unlock start");
        assertEq(actualVCA.timestamps().end, RANGED_STREAM_END_TIME, "unlock end");
    }
}
