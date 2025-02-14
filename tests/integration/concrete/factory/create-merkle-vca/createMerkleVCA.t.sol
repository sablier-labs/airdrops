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
    uint256 internal aggregateAmount;
    uint256 internal recipientCount;

    function setUp() public override {
        Integration_Test.setUp();

        aggregateAmount = defaults.AGGREGATE_AMOUNT();
        recipientCount = defaults.RECIPIENT_COUNT();
    }

    /// @dev This test reverts because a default MerkleVCA contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CampaignAlreadyExists() external {
        // This test fails
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        merkleFactory.createMerkleVCA({
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount
        });
    }

    function test_RevertWhen_VestingStartTimeZero() external givenCampaignNotExists {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.vesting.start = 0;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleFactory_VestingTimeZero.selector, 0, params.vesting.end)
        );
        merkleFactory.createMerkleVCA({
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount
        });
    }

    function test_RevertWhen_VestingEndTimeZero() external givenCampaignNotExists whenVestingStartTimeNotZero {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.vesting.end = 0;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleFactory_VestingTimeZero.selector, params.vesting.start, 0)
        );
        merkleFactory.createMerkleVCA({
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount
        });
    }

    function test_RevertWhen_VestingEndTimeLessThanStartTime()
        external
        givenCampaignNotExists
        whenVestingStartTimeNotZero
        whenVestingEndTimeNotZero
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        // Set the end time to be less than the start time.
        params.vesting.end = defaults.RANGED_STREAM_START_TIME() - 1;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleFactory_VestingStartTimeExceedsEndTime.selector,
                params.vesting.start,
                params.vesting.end
            )
        );
        merkleFactory.createMerkleVCA({
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount
        });
    }

    function test_WhenZeroExpiry()
        external
        givenCampaignNotExists
        whenVestingStartTimeNotZero
        whenVestingEndTimeNotZero
        whenVestingEndTimeNotLessThanStartTime
    {
        address expectedMerkleVCA = computeMerkleVCAAddress({ campaignOwner: users.sender, expiration: 0 });

        // It should emit a {CreateMerkleVCA} event.
        vm.expectEmit(address(merkleFactory));
        emit ISablierMerkleFactory.CreateMerkleVCA({
            merkleVCA: ISablierMerkleVCA(address(expectedMerkleVCA)),
            params: merkleVCAConstructorParams({ campaignOwner: users.sender, expiration: 0 }),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT(),
            fee: defaults.MINIMUM_FEE()
        });

        ISablierMerkleVCA actualVCA = createMerkleVCA({ campaignOwner: users.sender, expiration: 0 });

        // It should create the campaign with custom fee.
        assertEq(actualVCA.MINIMUM_FEE(), defaults.MINIMUM_FEE(), "minimum fee");

        // It should set the current factory address.
        assertEq(actualVCA.FACTORY(), address(merkleFactory), "factory");

        // It should set return the correct vesting schedule.
        assertEq(actualVCA.vestingSchedule().start, defaults.RANGED_STREAM_START_TIME(), "vesting start");
        assertEq(actualVCA.vestingSchedule().end, defaults.RANGED_STREAM_END_TIME(), "vesting end");
    }

    function test_RevertWhen_ClaimExpiresWithinOneWeek()
        external
        givenCampaignNotExists
        whenVestingStartTimeNotZero
        whenVestingEndTimeNotZero
        whenVestingEndTimeNotLessThanStartTime
        whenNotZeroExpiry
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.expiration = defaults.RANGED_STREAM_END_TIME() + 1 weeks - 1;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleFactory_ExpiryWithinOneWeekOfVestingEnd.selector,
                params.vesting.end,
                params.expiration
            )
        );
        merkleFactory.createMerkleVCA(params, aggregateAmount, recipientCount);
    }

    function test_GivenCustomFeeSet()
        external
        givenCampaignNotExists
        whenVestingStartTimeNotZero
        whenVestingEndTimeNotZero
        whenVestingEndTimeNotLessThanStartTime
        whenNotZeroExpiry
        whenClaimNotExpireWithinOneWeek
    {
        // Set the custom fee to 0 for this test.
        resetPrank(users.admin);
        merkleFactory.setCustomFee(users.campaignOwner, 0);

        resetPrank(users.campaignOwner);
        address expectedMerkleVCA =
            computeMerkleVCAAddress({ campaignOwner: users.sender, expiration: defaults.EXPIRATION() });

        // It should emit a {CreateMerkleVCA} event.
        vm.expectEmit(address(merkleFactory));
        emit ISablierMerkleFactory.CreateMerkleVCA({
            merkleVCA: ISablierMerkleVCA(address(expectedMerkleVCA)),
            params: merkleVCAConstructorParams({ campaignOwner: users.sender, expiration: defaults.EXPIRATION() }),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT(),
            fee: 0
        });

        ISablierMerkleVCA actualVCA =
            createMerkleVCA({ campaignOwner: users.sender, expiration: defaults.EXPIRATION() });
        assertGt(address(actualVCA).code.length, 0, "MerkleVCA contract not created");
        assertEq(address(actualVCA), expectedMerkleVCA, "MerkleVCA contract does not match computed address");

        // It should create the campaign with 0 custom fee.
        assertEq(actualVCA.MINIMUM_FEE(), 0, "custom fee");

        // It should set the current factory address.
        assertEq(actualVCA.FACTORY(), address(merkleFactory), "factory");

        // It should set return the correct vesting schedule.
        assertEq(actualVCA.vestingSchedule().start, defaults.RANGED_STREAM_START_TIME(), "vesting start");
        assertEq(actualVCA.vestingSchedule().end, defaults.RANGED_STREAM_END_TIME(), "vesting end");
    }

    function test_GivenCustomFeeNotSet()
        external
        givenCampaignNotExists
        whenVestingStartTimeNotZero
        whenVestingEndTimeNotZero
        whenVestingEndTimeNotLessThanStartTime
        whenNotZeroExpiry
        whenClaimNotExpireWithinOneWeek
    {
        address expectedMerkleVCA =
            computeMerkleVCAAddress({ campaignOwner: users.sender, expiration: defaults.EXPIRATION() });

        // It should emit a {CreateMerkleVCA} event.
        vm.expectEmit(address(merkleFactory));
        emit ISablierMerkleFactory.CreateMerkleVCA({
            merkleVCA: ISablierMerkleVCA(address(expectedMerkleVCA)),
            params: merkleVCAConstructorParams({ campaignOwner: users.sender, expiration: defaults.EXPIRATION() }),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT(),
            fee: defaults.MINIMUM_FEE()
        });

        ISablierMerkleVCA actualVCA =
            createMerkleVCA({ campaignOwner: users.sender, expiration: defaults.EXPIRATION() });
        assertGt(address(actualVCA).code.length, 0, "MerkleVCA contract not created");
        assertEq(address(actualVCA), expectedMerkleVCA, "MerkleVCA contract does not match computed address");

        // It should create the campaign with custom fee.
        assertEq(actualVCA.MINIMUM_FEE(), defaults.MINIMUM_FEE(), "minimum fee");

        // It should set the current factory address.
        assertEq(actualVCA.FACTORY(), address(merkleFactory), "factory");

        // It should set return the correct vesting schedule.
        assertEq(actualVCA.vestingSchedule().start, defaults.RANGED_STREAM_START_TIME(), "vesting start");
        assertEq(actualVCA.vestingSchedule().end, defaults.RANGED_STREAM_END_TIME(), "vesting end");
    }
}
