// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, ZERO } from "@prb/math/src/UD60x18.sol";
import { Errors as LockupErrors } from "@sablier/lockup/src/libraries/Errors.sol";
import { Lockup } from "@sablier/lockup/src/types/DataTypes.sol";

import { ISablierMerkleLockup } from "src/interfaces/ISablierMerkleLockup.sol";
import { MerkleLL } from "src/types/DataTypes.sol";

import { Claim_Integration_Test } from "../../shared/claim/claim.t.sol";
import { MerkleLL_Integration_Shared_Test, Integration_Test } from "../MerkleLL.t.sol";

contract Claim_MerkleLL_Integration_Test is Claim_Integration_Test, MerkleLL_Integration_Shared_Test {
    function setUp() public virtual override(MerkleLL_Integration_Shared_Test, Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
    }

    function test_WhenVestingEndTimeNotExceedClaimTime() external whenMerkleProofValid {
        // Forward in time to the end of the vesting period.
        vm.warp({ newTimestamp: RANGED_STREAM_END_TIME });

        uint256 expectedRecipientBalance = dai.balanceOf(users.recipient1) + CLAIM_AMOUNT;

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleLL) });
        emit ISablierMerkleLockup.Claim(INDEX1, users.recipient1, CLAIM_AMOUNT);

        expectCallToTransfer({ to: users.recipient1, value: CLAIM_AMOUNT });
        expectCallToClaimWithMsgValue(address(merkleLL), MIN_FEE_WEI);

        merkleLL.claim{ value: MIN_FEE_WEI }(INDEX1, users.recipient1, CLAIM_AMOUNT, index1Proof());

        // It should transfer the tokens to the recipient.
        assertEq(dai.balanceOf(users.recipient1), expectedRecipientBalance, "recipient balance");
    }

    function test_RevertWhen_TotalPercentageGreaterThan100()
        external
        whenMerkleProofValid
        whenVestingEndTimeExceedsClaimTime
    {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();

        // Crate a MerkleLL campaign with a total percentage greater than 100.
        params.startUnlockPercentage = ud(0.5e18);
        params.cliffUnlockPercentage = ud(0.6e18);

        merkleLL = factoryMerkleLL.createMerkleLL(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);
        uint128 startUnlockAmount = ud(CLAIM_AMOUNT).mul(ud(0.5e18)).intoUint128();
        uint128 cliffUnlockAmount = ud(CLAIM_AMOUNT).mul(ud(0.6e18)).intoUint128();

        vm.expectRevert(
            abi.encodeWithSelector(
                LockupErrors.SablierHelpers_UnlockAmountsSumTooHigh.selector,
                CLAIM_AMOUNT,
                startUnlockAmount,
                cliffUnlockAmount
            )
        );

        // Claim the airdrop.
        merkleLL.claim{ value: MIN_FEE_WEI }({
            index: 1,
            recipient: users.recipient1,
            amount: CLAIM_AMOUNT,
            merkleProof: index1Proof()
        });
    }

    function test_WhenStartTimeZero()
        external
        whenMerkleProofValid
        whenVestingEndTimeExceedsClaimTime
        whenTotalPercentageNotGreaterThan100
    {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();
        params.startTime = 0;

        merkleLL = factoryMerkleLL.createMerkleLL(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);

        // It should create a stream with block.timestamp as start time.
        _test_Claim({ startTime: getBlockTimestamp(), cliffTime: getBlockTimestamp() + CLIFF_DURATION });
    }

    function test_WhenCliffDurationZero()
        external
        whenMerkleProofValid
        whenVestingEndTimeExceedsClaimTime
        whenTotalPercentageNotGreaterThan100
        whenStartTimeNotZero
    {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();
        params.cliffDuration = 0;
        params.cliffUnlockPercentage = ZERO;

        merkleLL = factoryMerkleLL.createMerkleLL(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);

        // It should create a stream with block.timestamp as start time.
        // It should create a stream with cliff as zero.
        _test_Claim({ startTime: RANGED_STREAM_START_TIME, cliffTime: 0 });
    }

    function test_WhenCliffDurationNotZero()
        external
        whenMerkleProofValid
        whenVestingEndTimeExceedsClaimTime
        whenTotalPercentageNotGreaterThan100
        whenStartTimeNotZero
    {
        // It should create a stream with block.timestamp as start time.
        // It should create a stream with cliff as start time + cliff duration.
        _test_Claim({ startTime: RANGED_STREAM_START_TIME, cliffTime: RANGED_STREAM_START_TIME + CLIFF_DURATION });
    }

    /// @dev Helper function to test claim.
    function _test_Claim(uint40 startTime, uint40 cliffTime) private {
        deal({ token: address(dai), to: address(merkleLL), give: AGGREGATE_AMOUNT });

        uint256 expectedStreamId = lockup.nextStreamId();
        uint256 previousFeeAccrued = address(merkleLL).balance;

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleLL) });
        emit ISablierMerkleLockup.Claim(INDEX1, users.recipient1, CLAIM_AMOUNT, expectedStreamId);

        expectCallToTransferFrom({ from: address(merkleLL), to: address(lockup), value: CLAIM_AMOUNT });
        expectCallToClaimWithMsgValue(address(merkleLL), MIN_FEE_WEI);

        // Claim the airstream.
        merkleLL.claim{ value: MIN_FEE_WEI }(INDEX1, users.recipient1, CLAIM_AMOUNT, index1Proof());

        uint128 expectedCliffAmount = cliffTime > 0 ? CLIFF_AMOUNT : 0;

        // Assert that the stream has been created successfully.
        assertEq(lockup.getCliffTime(expectedStreamId), cliffTime, "cliff time");
        assertEq(lockup.getDepositedAmount(expectedStreamId), CLAIM_AMOUNT, "depositedAmount");
        assertEq(lockup.getEndTime(expectedStreamId), startTime + TOTAL_DURATION, "end time");
        assertEq(lockup.getRecipient(expectedStreamId), users.recipient1, "recipient");
        assertEq(lockup.getSender(expectedStreamId), users.campaignCreator, "sender");
        assertEq(lockup.getStartTime(expectedStreamId), startTime, "start time");
        assertEq(lockup.getUnderlyingToken(expectedStreamId), dai, "token");
        assertEq(lockup.getUnlockAmounts(expectedStreamId).cliff, expectedCliffAmount, "unlock amount cliff");
        assertEq(lockup.getUnlockAmounts(expectedStreamId).start, START_AMOUNT, "unlock amount start");
        assertEq(lockup.isCancelable(expectedStreamId), STREAM_CANCELABLE, "is cancelable");
        assertEq(lockup.isDepleted(expectedStreamId), false, "is depleted");
        assertEq(lockup.isStream(expectedStreamId), true, "is stream");
        assertEq(lockup.isTransferable(expectedStreamId), STREAM_TRANSFERABLE, "is transferable");
        assertEq(lockup.wasCanceled(expectedStreamId), false, "was canceled");

        assertTrue(merkleLL.hasClaimed(INDEX1), "not claimed");

        // It should create the stream with the correct Lockup model.
        assertEq(lockup.getLockupModel(expectedStreamId), Lockup.Model.LOCKUP_LINEAR);

        uint256[] memory expectedClaimedStreamIds = new uint256[](1);
        expectedClaimedStreamIds[0] = expectedStreamId;
        assertEq(merkleLL.claimedStreams(users.recipient1), expectedClaimedStreamIds, "claimed streams");

        assertEq(address(merkleLL).balance, previousFeeAccrued + MIN_FEE_WEI, "fee collected");
    }
}
