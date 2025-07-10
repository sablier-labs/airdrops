// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleVCA } from "src/types/DataTypes.sol";

import { ClaimTo_Integration_Test } from "../../shared/claim-to/claimTo.t.sol";
import { MerkleVCA_Integration_Shared_Test } from "../MerkleVCA.t.sol";

contract ClaimTo_MerkleVCA_Integration_Test is ClaimTo_Integration_Test, MerkleVCA_Integration_Shared_Test {
    function setUp() public virtual override(MerkleVCA_Integration_Shared_Test, ClaimTo_Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
        ClaimTo_Integration_Test.setUp();
    }

    function test_RevertGiven_CampaignStartTimeInFuture() external {
        uint40 warpTime = CAMPAIGN_START_TIME - 1 seconds;
        vm.warp({ newTimestamp: warpTime });

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleBase_CampaignNotStarted.selector, warpTime, CAMPAIGN_START_TIME)
        );
        claimTo();
    }

    function test_RevertGiven_CampaignExpired() external givenCampaignStartTimeNotInFuture {
        uint40 warpTime = EXPIRATION + 1 seconds;
        vm.warp({ newTimestamp: warpTime });

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_CampaignExpired.selector, warpTime, EXPIRATION));
        claimTo();
    }

    function test_RevertGiven_MsgValueLessThanFee()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
    {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleBase_InsufficientFeePayment.selector, 0, AIRDROP_MIN_FEE_WEI)
        );
        claimTo({
            msgValue: 0,
            index: getIndexInMerkleTree(),
            to: users.recipient,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof()
        });
    }

    function test_RevertGiven_RecipientClaimed()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
    {
        claimTo();

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_IndexClaimed.selector, getIndexInMerkleTree()));
        claimTo();
    }

    function test_RevertWhen_IndexNotValid()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
    {
        uint256 invalidIndex = 1337;

        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        claimTo({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: invalidIndex,
            to: users.recipient,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof()
        });
    }

    function test_RevertWhen_AmountNotValid()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
    {
        uint128 invalidAmount = 1337;

        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        claimTo({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            to: users.recipient,
            amount: invalidAmount,
            merkleProof: getMerkleProof()
        });
    }

    function test_RevertWhen_MerkleProofNotValid()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenAmountValid
    {
        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        claimTo({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            to: users.recipient,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(users.unknownRecipient)
        });
    }

    /// @dev The test for the modifiers added below can be found in {ClaimTo_Integration_Test}.

    function test_RevertWhen_VestingStartTimeInFuture()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenAmountValid
        whenToAddressNotZero
        givenCallerNotClaimed
        whenCallerEligible
        whenMerkleProofValid
    {
        // Create a new campaign with vesting start time in the future.
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.vestingStartTime = getBlockTimestamp() + 1 seconds;
        merkleVCA = createMerkleVCA(params);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleVCA_ClaimAmountZero.selector, users.recipient));

        // Claim the airdrop.
        merkleVCA.claimTo{ value: AIRDROP_MIN_FEE_WEI }({
            index: getIndexInMerkleTree(),
            to: users.eve,
            fullAmount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof()
        });
    }

    function test_WhenVestingStartTimeInPresent()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenAmountValid
        whenToAddressNotZero
        givenCallerNotClaimed
        whenCallerEligible
        whenMerkleProofValid
        whenVestingStartTimeNotInFuture
    {
        // Create a new campaign with vesting start time in the present.
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.vestingStartTime = getBlockTimestamp();
        merkleVCA = createMerkleVCA(params);

        _test_ClaimTo(VCA_UNLOCK_AMOUNT);
    }

    function test_WhenVestingEndTimeInPast()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenAmountValid
        whenToAddressNotZero
        givenCallerNotClaimed
        whenCallerEligible
        whenMerkleProofValid
        whenVestingStartTimeNotInFuture
    {
        // Forward in time so that the vesting end time is in the past.
        vm.warp({ newTimestamp: VESTING_END_TIME });

        _test_ClaimTo(VCA_FULL_AMOUNT);
    }

    function test_WhenVestingEndTimeNotInPast()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenAmountValid
        whenToAddressNotZero
        givenCallerNotClaimed
        whenCallerEligible
        whenMerkleProofValid
        whenVestingStartTimeNotInFuture
    {
        _test_ClaimTo(VCA_CLAIM_AMOUNT);
    }

    function _test_ClaimTo(uint128 claimAmount) private {
        // Cast the {MerkleVCA} contract as {ISablierMerkleBase}.
        merkleBase = merkleVCA;

        uint256 index = getIndexInMerkleTree();

        uint128 forgoneAmount = VCA_FULL_AMOUNT - claimAmount;
        uint256 previousFeeAccrued = address(comptroller).balance;

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.ClaimVCA({
            index: index,
            recipient: users.recipient,
            claimAmount: claimAmount,
            forgoneAmount: forgoneAmount,
            to: users.eve,
            viaSig: false
        });

        // It should transfer a portion of the amount to Eve.
        expectCallToTransfer({ to: users.eve, value: claimAmount });
        expectCallToClaimToWithMsgValue(address(merkleVCA), AIRDROP_MIN_FEE_WEI);

        claimTo();

        // It should update the claimed status.
        assertTrue(merkleVCA.hasClaimed(index), "not claimed");

        // It should update the total forgone amount.
        assertEq(merkleVCA.totalForgoneAmount(), forgoneAmount, "total forgone amount");

        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee collected");
    }
}
