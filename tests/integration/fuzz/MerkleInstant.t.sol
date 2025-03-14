// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactoryInstant } from "src/interfaces/ISablierMerkleFactoryInstant.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";

import { MerkleInstant } from "src/types/DataTypes.sol";

import { Shared_Fuzz_Test } from "./Fuzz.t.sol";

contract MerkleInstant_Fuzz_Test is Shared_Fuzz_Test {
    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - Fuzzed custom fee.
    /// - MerkleInstant campaign with fuzzed allocations, and expiration.
    /// - Both finite (only in future) and infinite expiration.
    /// - Claiming multiple airdrops with fuzzed claim fee at different point in time.
    /// - Fuzzed clawback amount.
    /// - Collect fees earned.
    function testFuzz_MerkleInstant(
        Allocation[] memory allocation,
        uint128 clawbackAmount,
        uint256 feeForUser,
        bool enableCustomFee,
        uint40 expiration,
        uint256[] memory indexesToClaim,
        uint256 msgValue
    )
        external
    {
        // Ensure that allocation data is not empty.
        vm.assume(allocation.length > 0 && indexesToClaim.length < allocation.length);

        // Bound expiration so that the campaign is still active at the block time.
        if (expiration > 0) expiration = boundUint40(expiration, getBlockTimestamp() + 365 days, MAX_UNIX_TIMESTAMP);

        // Set the custom fee if enabled.
        feeForUser = enableCustomFee ? testSetCustomFee(merkleFactoryInstant, feeForUser) : MINIMUM_FEE;

        // Construct merkle root for the given allocation data.
        (uint256 aggregateAmount, bytes32 merkleRoot) = constructMerkleTree(allocation);

        // Test creating the MerkleInstant campaign.
        _testCreateMerkleInstant(aggregateAmount, expiration, feeForUser, merkleRoot);

        // Test claiming the airdrop for the given indexes.
        testClaimMultipleAirdrops(merkleInstant, indexesToClaim, msgValue);

        // Test clawbacking funds.
        testClawback(merkleInstant, clawbackAmount);

        // Test collecting fees earned.
        testCollectFees(merkleFactoryInstant, merkleInstant);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CREATE-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function _testCreateMerkleInstant(
        uint256 aggregateAmount,
        uint40 expiration,
        uint256 feeForUser,
        bytes32 merkleRoot
    )
        private
        givenCampaignNotExists
    {
        // Set campaign creator as the caller.
        resetPrank(users.campaignCreator);

        MerkleInstant.ConstructorParams memory params = merkleInstantConstructorParams(expiration);
        params.merkleRoot = merkleRoot;

        // Precompute the deterministic address.
        address expectedMerkleInstant = computeMerkleInstantAddress(params, users.campaignCreator);

        // Expect a {CreateMerkleInstant} event.
        vm.expectEmit({ emitter: address(merkleFactoryInstant) });
        emit ISablierMerkleFactoryInstant.CreateMerkleInstant({
            merkleInstant: ISablierMerkleInstant(expectedMerkleInstant),
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: allotment.length,
            fee: feeForUser,
            oracle: address(oracle)
        });

        // Create the campaign.
        merkleInstant = merkleFactoryInstant.createMerkleInstant(params, aggregateAmount, allotment.length);

        // It should deploy the contract at the correct address.
        assertGt(address(merkleInstant).code.length, 0, "MerkleInstant contract not created");
        assertEq(
            address(merkleInstant), expectedMerkleInstant, "MerkleInstant contract does not match computed address"
        );

        // It should return false for hasExpired.
        assertFalse(merkleInstant.hasExpired(), "isExpired");

        // Fund the MerkleInstant contract.
        deal({ token: address(dai), to: address(merkleInstant), give: aggregateAmount });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CLAIM-EVENT-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function expectClaimEvent(Allocation memory allocation) internal override {
        // it should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleInstant) });
        emit ISablierMerkleInstant.Claim(allocation.index, allocation.recipient, allocation.amount);

        // It should transfer the allocation amount to the recipient.
        expectCallToTransfer({ token: dai, to: allocation.recipient, value: allocation.amount });
    }
}
