// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { Lockup } from "@sablier/lockup/src/types/DataTypes.sol";

import { ISablierMerkleLockup } from "src/interfaces/ISablierMerkleLockup.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleLT } from "src/types/DataTypes.sol";

import { Claim_Integration_Test } from "../../shared/claim/claim.t.sol";
import { MerkleLT_Integration_Shared_Test, Integration_Test } from "../MerkleLT.t.sol";

contract Claim_MerkleLT_Integration_Test is Claim_Integration_Test, MerkleLT_Integration_Shared_Test {
    function setUp() public virtual override(MerkleLT_Integration_Shared_Test, Integration_Test) {
        MerkleLT_Integration_Shared_Test.setUp();
    }

    function test_WhenVestingEndTimeNotExceedClaimTime() external whenMerkleProofValid {
        // Forward in time to the end of the vesting period.
        vm.warp({ newTimestamp: VESTING_END_TIME });

        uint256 expectedRecipientBalance = dai.balanceOf(users.recipient1) + CLAIM_AMOUNT;

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleLT) });
        emit ISablierMerkleLockup.Claim(INDEX1, users.recipient1, CLAIM_AMOUNT);

        expectCallToTransfer({ to: users.recipient1, value: CLAIM_AMOUNT });
        expectCallToClaimWithMsgValue(address(merkleLT), MIN_FEE_WEI);

        merkleLT.claim{ value: MIN_FEE_WEI }(INDEX1, users.recipient1, CLAIM_AMOUNT, index1Proof());

        // It should transfer the tokens to the recipient.
        assertEq(dai.balanceOf(users.recipient1), expectedRecipientBalance, "recipient balance");
    }

    function test_RevertWhen_TotalPercentageLessThan100()
        external
        whenMerkleProofValid
        whenVestingEndTimeExceedsClaimTime
        whenTotalPercentageNot100
    {
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();

        // Create a MerkleLT campaign with a total percentage less than 100.
        params.tranchesWithPercentages[0].unlockPercentage = ud2x18(0.05e18);
        params.tranchesWithPercentages[1].unlockPercentage = ud2x18(0.2e18);

        merkleLT = factoryMerkleLT.createMerkleLT(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleLT_TotalPercentageNotOneHundred.selector, 0.25e18));

        merkleLT.claim{ value: MIN_FEE_WEI }({
            index: 1,
            recipient: users.recipient1,
            amount: 10_000e18,
            merkleProof: index1Proof()
        });
    }

    function test_RevertWhen_TotalPercentageGreaterThan100()
        external
        whenMerkleProofValid
        whenVestingEndTimeExceedsClaimTime
        whenTotalPercentageNot100
    {
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();

        // Create a MerkleLT campaign with a total percentage less than 100.
        params.tranchesWithPercentages[0].unlockPercentage = ud2x18(0.75e18);
        params.tranchesWithPercentages[1].unlockPercentage = ud2x18(0.8e18);

        merkleLT = factoryMerkleLT.createMerkleLT(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleLT_TotalPercentageNotOneHundred.selector, 1.55e18));

        merkleLT.claim{ value: MIN_FEE_WEI }({
            index: 1,
            recipient: users.recipient1,
            amount: 10_000e18,
            merkleProof: index1Proof()
        });
    }

    function test_WhenVestingStartTimeZero()
        external
        whenMerkleProofValid
        whenVestingEndTimeExceedsClaimTime
        whenTotalPercentage100
    {
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();
        params.startTime = 0;

        merkleLT = factoryMerkleLT.createMerkleLT(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);

        // It should create a stream with `block.timestamp` as vesting start time.
        _test_Claim({ vestingStartTime: 0, startTime: getBlockTimestamp() });
    }

    function test_WhenVestingStartTimeNotZero()
        external
        whenMerkleProofValid
        whenVestingEndTimeExceedsClaimTime
        whenTotalPercentage100
    {
        // It should create a ranged stream with provided start time.
        _test_Claim({ vestingStartTime: VESTING_START_TIME, startTime: VESTING_START_TIME });
    }

    /// @dev Helper function to test claim.
    function _test_Claim(uint40 vestingStartTime, uint40 startTime) private {
        deal({ token: address(dai), to: address(merkleLT), give: AGGREGATE_AMOUNT });

        uint256 expectedStreamId = lockup.nextStreamId();
        uint256 previousFeeAccrued = address(merkleLT).balance;

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleLT) });
        emit ISablierMerkleLockup.Claim(INDEX1, users.recipient1, CLAIM_AMOUNT, expectedStreamId);

        expectCallToTransferFrom({ from: address(merkleLT), to: address(lockup), value: CLAIM_AMOUNT });
        expectCallToClaimWithMsgValue(address(merkleLT), MIN_FEE_WEI);

        // Claim the airstream.
        merkleLT.claim{ value: MIN_FEE_WEI }(INDEX1, users.recipient1, CLAIM_AMOUNT, index1Proof());

        // Assert that the stream has been created successfully.
        assertEq(lockup.getDepositedAmount(expectedStreamId), CLAIM_AMOUNT, "depositedAmount");
        assertEq(lockup.getEndTime(expectedStreamId), startTime + VESTING_TOTAL_DURATION, "end time");
        assertEq(lockup.getRecipient(expectedStreamId), users.recipient1, "recipient");
        assertEq(lockup.getSender(expectedStreamId), users.campaignCreator, "sender");
        assertEq(lockup.getStartTime(expectedStreamId), startTime, "start time");
        // It should create a stream with `VESTING_START_TIME` as start time.
        assertEq(
            lockup.getTranches(expectedStreamId),
            tranchesMerkleLT({ vestingStartTime: vestingStartTime, totalAmount: CLAIM_AMOUNT })
        );
        assertEq(lockup.getUnderlyingToken(expectedStreamId), dai, "token");
        assertEq(lockup.isCancelable(expectedStreamId), STREAM_CANCELABLE, "is cancelable");
        assertEq(lockup.isDepleted(expectedStreamId), false, "is depleted");
        assertEq(lockup.isStream(expectedStreamId), true, "is stream");
        assertEq(lockup.isTransferable(expectedStreamId), STREAM_TRANSFERABLE, "is transferable");
        assertEq(lockup.wasCanceled(expectedStreamId), false, "was canceled");

        assertTrue(merkleLT.hasClaimed(INDEX1), "not claimed");

        // It should create the stream with the correct Lockup model.
        assertEq(lockup.getLockupModel(expectedStreamId), Lockup.Model.LOCKUP_TRANCHED);

        uint256[] memory expectedClaimedStreamIds = new uint256[](1);
        expectedClaimedStreamIds[0] = expectedStreamId;
        assertEq(merkleLT.claimedStreams(users.recipient1), expectedClaimedStreamIds, "claimed streams");

        assertEq(address(merkleLT).balance, previousFeeAccrued + MIN_FEE_WEI, "fee collected");
    }
}
