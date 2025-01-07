// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { ud60x18 } from "@prb/math/src/UD60x18.sol";
import { Errors as LockupErrors } from "@sablier/lockup/src/libraries/Errors.sol";

import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { MerkleLL } from "src/types/DataTypes.sol";

import { Claim_Integration_Test } from "../../shared/claim/claim.t.sol";
import { MerkleLL_Integration_Shared_Test, Integration_Test } from "../MerkleLL.t.sol";

contract Claim_MerkleLL_Integration_Test is Claim_Integration_Test, MerkleLL_Integration_Shared_Test {
    uint256 internal fee;
    address[] internal recipients;
    MerkleLL.Schedule internal schedule;

    function setUp() public virtual override(MerkleLL_Integration_Shared_Test, Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
        fee = defaults.FEE();
        recipients.push(users.recipient1);
        schedule = defaults.schedule();
    }

    function test_RevertWhen_TotalPercentageGreaterThan100() external whenMerkleProofValid {
        // Crate a MerkleLL campaign with a total percentage greater than 100.
        schedule.startPercentage = ud2x18(0.5e18);
        schedule.cliffPercentage = ud2x18(0.6e18);

        merkleLL = merkleFactory.createMerkleLL({
            baseParams: defaults.baseParams(),
            lockup: lockup,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            schedule: schedule,
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });

        uint128 depositAmount = defaults.CLAIM_AMOUNT();
        uint128 startUnlockAmount = ud60x18(depositAmount).mul(schedule.startPercentage.intoUD60x18()).intoUint128();
        uint128 cliffUnlockAmount = ud60x18(depositAmount).mul(schedule.cliffPercentage.intoUD60x18()).intoUint128();
        bytes32[] memory merkleProof = defaults.index1Proof();

        vm.expectRevert(
            abi.encodeWithSelector(
                LockupErrors.SablierHelpers_UnlockAmountsSumTooHigh.selector,
                depositAmount,
                startUnlockAmount,
                cliffUnlockAmount
            )
        );

        // Claim the airdrop.
        merkleLL.claim{ value: fee }({
            index: 1,
            recipient: users.recipient1,
            amount: depositAmount,
            merkleProof: merkleProof
        });
    }

    function test_WhenScheduledCliffDurationZero()
        external
        whenMerkleProofValid
        whenTotalPercentageNotGreaterThan100
        whenScheduledStartTimeZero
    {
        schedule.cliffDuration = 0;
        schedule.cliffPercentage = ud2x18(0);

        merkleLL = merkleFactory.createMerkleLL({
            baseParams: defaults.baseParams(),
            lockup: lockup,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            schedule: schedule,
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });

        // It should create a stream with block.timestamp as start time.
        // It should create a stream with cliff as zero.
        _test_Claim({ _merkleLL: merkleLL, startTime: getBlockTimestamp(), cliffTime: 0 });
    }

    function test_WhenScheduledCliffDurationNotZero()
        external
        whenMerkleProofValid
        whenTotalPercentageNotGreaterThan100
        whenScheduledStartTimeZero
    {
        // It should create a stream with block.timestamp as start time.
        // It should create a stream with cliff as start time + cliff duration.
        _test_Claim({
            _merkleLL: merkleLL,
            startTime: getBlockTimestamp(),
            cliffTime: getBlockTimestamp() + defaults.CLIFF_DURATION()
        });
    }

    modifier whenScheduledStartTimeNotZero() {
        _;
    }

    modifier givenRecipientAborted() {
        _;
    }

    function test_GivenAbortTimeNotGreaterThanStartTime()
        external
        whenMerkleProofValid
        whenTotalPercentageNotGreaterThan100
        whenScheduledStartTimeNotZero
        givenRecipientAborted
    {
        // It should do nothing

        // Abort the recipient
        vm.warp({ newTimestamp: defaults.STREAM_START_TIME_NON_ZERO() - 1 seconds });
        merkleLLFixedStartTime.abort(recipients);
        vm.warp({ newTimestamp: defaults.STREAM_START_TIME_NON_ZERO() + 1 seconds });

        expectCallToTransfer({ to: recipients[0], value: 0 });

        bytes32[] memory merkleProof = defaults.index1Proof();
        uint128 amount = defaults.CLAIM_AMOUNT();

        vm.expectEmit({ emitter: address(merkleLLFixedStartTime) });
        emit ISablierMerkleLL.Claim(1, recipients[0], 0, 0);

        merkleLLFixedStartTime.claim{ value: fee }(1, recipients[0], amount, merkleProof);

        assertTrue(merkleLLFixedStartTime.hasClaimed(defaults.INDEX1()), "not claimed");
    }

    modifier givenAbortTimeGreaterThanStartTime() {
        _;
    }

    function test_GivenAbortTimeNotGreaterThanEndTime()
        external
        whenMerkleProofValid
        whenTotalPercentageNotGreaterThan100
        whenScheduledStartTimeNotZero
        givenRecipientAborted
        givenAbortTimeGreaterThanStartTime
    {
        // Declare the abort time half way through.
        uint40 abortTime = defaults.STREAM_START_TIME_NON_ZERO() + defaults.CLIFF_DURATION() / 2;

        // Abort the recipient
        vm.warp({ newTimestamp: abortTime });
        merkleLLFixedStartTime.abort(recipients);

        uint128 amount = defaults.CLAIM_AMOUNT();
        uint128 claimableAmount = defaults.START_AMOUNT();
        uint256 index = defaults.INDEX1();
        bytes32[] memory merkleProof = defaults.index1Proof();

        // It should transfer the claimable amount
        expectCallToTransfer({ to: recipients[0], value: claimableAmount });

        // It should emit a {Claim} event
        vm.expectEmit({ emitter: address(merkleLLFixedStartTime) });
        emit ISablierMerkleLL.Claim(index, recipients[0], claimableAmount, 0);

        // Claim the airstream
        merkleLLFixedStartTime.claim{ value: fee }(index, recipients[0], amount, merkleProof);

        assertTrue(merkleLLFixedStartTime.hasClaimed(index), "not claimed");
    }

    function test_GivenAbortTimeGreaterThanEndTime()
        external
        whenMerkleProofValid
        whenTotalPercentageNotGreaterThan100
        whenScheduledStartTimeNotZero
        givenRecipientAborted
        givenAbortTimeGreaterThanStartTime
    {
        // Declare the abort time half way through.
        uint40 abortTime = defaults.STREAM_START_TIME_NON_ZERO() + defaults.TOTAL_DURATION() + 1 seconds;

        // Abort the recipient
        vm.warp({ newTimestamp: abortTime });
        merkleLLFixedStartTime.abort(recipients);

        uint128 claimableAmount = defaults.CLAIM_AMOUNT();
        uint256 index = defaults.INDEX1();
        bytes32[] memory merkleProof = defaults.index1Proof();

        // It should transfer the claimable amount
        expectCallToTransfer({ to: recipients[0], value: claimableAmount });

        // // It should emit a {Claim} event
        vm.expectEmit({ emitter: address(merkleLLFixedStartTime) });
        emit ISablierMerkleLL.Claim(index, recipients[0], claimableAmount, 0);

        // Claim the airstream
        merkleLLFixedStartTime.claim{ value: fee }(index, recipients[0], claimableAmount, merkleProof);

        assertTrue(merkleLLFixedStartTime.hasClaimed(index), "not claimed");
    }

    function test_GivenRecipientNotAborted()
        external
        whenMerkleProofValid
        whenTotalPercentageNotGreaterThan100
        whenScheduledStartTimeNotZero
    {
        uint40 startTime = defaults.STREAM_START_TIME_NON_ZERO();

        // Warp before the stream end time.
        vm.warp({ newTimestamp: startTime + defaults.TOTAL_DURATION() - 1 });

        // It should create a stream with scheduled start time as start time.
        _test_Claim({
            _merkleLL: merkleLLFixedStartTime,
            startTime: startTime,
            cliffTime: defaults.STREAM_START_TIME_NON_ZERO() + defaults.CLIFF_DURATION()
        });
    }

    /// @dev Helper function to test claim.
    function _test_Claim(ISablierMerkleLL _merkleLL, uint40 startTime, uint40 cliffTime) private {
        deal({ token: address(dai), to: address(_merkleLL), give: defaults.AGGREGATE_AMOUNT() });

        uint256 expectedStreamId = lockup.nextStreamId();
        uint256 previousFeeAccrued = address(_merkleLL).balance;

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(_merkleLL) });
        emit ISablierMerkleLL.Claim(defaults.INDEX1(), users.recipient1, defaults.CLAIM_AMOUNT(), expectedStreamId);

        expectCallToTransferFrom({ from: address(_merkleLL), to: address(lockup), value: defaults.CLAIM_AMOUNT() });
        expectCallToClaimWithMsgValue(address(_merkleLL), fee);

        // Claim the airstream.
        _merkleLL.claim{ value: fee }(
            defaults.INDEX1(), users.recipient1, defaults.CLAIM_AMOUNT(), defaults.index1Proof()
        );

        uint128 expectedCliffAmount = cliffTime > 0 ? defaults.CLIFF_AMOUNT() : 0;

        // Assert that the stream has been created successfully.
        assertEq(lockup.getCliffTime(expectedStreamId), cliffTime, "cliff time");
        assertEq(lockup.getDepositedAmount(expectedStreamId), defaults.CLAIM_AMOUNT(), "depositedAmount");
        assertEq(lockup.getEndTime(expectedStreamId), startTime + defaults.TOTAL_DURATION(), "end time");
        assertEq(lockup.getRecipient(expectedStreamId), users.recipient1, "recipient");
        assertEq(lockup.getSender(expectedStreamId), users.campaignOwner, "sender");
        assertEq(lockup.getStartTime(expectedStreamId), startTime, "start time");
        assertEq(lockup.getUnderlyingToken(expectedStreamId), dai, "token");
        assertEq(lockup.getUnlockAmounts(expectedStreamId).cliff, expectedCliffAmount, "unlock amount cliff");
        assertEq(lockup.getUnlockAmounts(expectedStreamId).start, defaults.START_AMOUNT(), "unlock amount start");
        assertEq(lockup.isCancelable(expectedStreamId), defaults.CANCELABLE(), "is cancelable");
        assertEq(lockup.isDepleted(expectedStreamId), false, "is depleted");
        assertEq(lockup.isStream(expectedStreamId), true, "is stream");
        assertEq(lockup.isTransferable(expectedStreamId), defaults.TRANSFERABLE(), "is transferable");
        assertEq(lockup.wasCanceled(expectedStreamId), false, "was canceled");

        assertTrue(_merkleLL.hasClaimed(defaults.INDEX1()), "not claimed");

        assertEq(address(_merkleLL).balance, previousFeeAccrued + defaults.FEE(), "fee collected");
    }
}
