// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract ClaimTo_Integration_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Make `users.recipient1` the caller for this test.
        setMsgSender(users.recipient1);
    }

    function test_RevertWhen_ToAddressZero() external {
        vm.expectRevert(Errors.SablierMerkleBase_ToZeroAddress.selector);
        claimTo({
            msgValue: MIN_FEE_WEI,
            index: INDEX1,
            to: address(0),
            amount: CLAIM_AMOUNT,
            merkleProof: index1Proof()
        });
    }

    function test_RevertGiven_CampaignExpired() external whenToAddressNotZero {
        uint256 warpTime = EXPIRATION + 1 seconds;
        vm.warp({ newTimestamp: warpTime });

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_CampaignExpired.selector, warpTime, EXPIRATION));
        claimTo();
    }

    function test_RevertGiven_MsgValueLessThanFee() external whenToAddressNotZero givenCampaignNotExpired {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleBase_InsufficientFeePayment.selector, 0, MIN_FEE_WEI)
        );
        claimTo({ msgValue: 0, index: INDEX1, to: users.eve, amount: CLAIM_AMOUNT, merkleProof: index1Proof() });
    }

    function test_RevertGiven_CallerClaimed()
        external
        whenToAddressNotZero
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
    {
        claimTo();

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_IndexClaimed.selector, INDEX1));
        claimTo();
    }

    function test_RevertWhen_IndexNotValid()
        external
        whenToAddressNotZero
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenCallerNotClaimed
    {
        uint256 invalidIndex = 1337;

        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        claimTo({
            msgValue: MIN_FEE_WEI,
            index: invalidIndex,
            to: users.eve,
            amount: CLAIM_AMOUNT,
            merkleProof: index1Proof()
        });
    }

    function test_RevertWhen_CallerNotEligible()
        external
        whenToAddressNotZero
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenCallerNotClaimed
        whenIndexValid
    {
        setMsgSender(address(1337));

        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        claimTo();
    }

    function test_RevertWhen_AmountNotValid()
        external
        whenToAddressNotZero
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenCallerNotClaimed
        whenIndexValid
        whenCallerEligible
    {
        uint128 invalidAmount = 1337;

        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        claimTo({
            msgValue: MIN_FEE_WEI,
            index: INDEX1,
            to: users.eve,
            amount: invalidAmount,
            merkleProof: index1Proof()
        });
    }

    function test_RevertWhen_MerkleProofNotValid()
        external
        whenToAddressNotZero
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenCallerNotClaimed
        whenIndexValid
        whenCallerEligible
        whenAmountValid
    {
        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        claimTo({ msgValue: MIN_FEE_WEI, index: INDEX1, to: users.eve, amount: CLAIM_AMOUNT, merkleProof: index2Proof() });
    }

    /// @dev Since the implementation of `claimTo()` differs in each Merkle campaign, we declare this dummy test. The
    /// child contracts implement the rest of the tests.
    function test_WhenMerkleProofValid()
        external
        whenToAddressNotZero
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenCallerNotClaimed
        whenIndexValid
        whenCallerEligible
        whenAmountValid
    {
        // The child contract must check that the claim event is emitted.
        // It should mark the index as claimed.
        // It should transfer the fee from the caller address to the merkle lockup.
    }
}
