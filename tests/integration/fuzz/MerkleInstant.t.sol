// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactoryInstant } from "src/interfaces/ISablierMerkleFactoryInstant.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";

import { MerkleInstant } from "src/types/DataTypes.sol";

import { Shared_Fuzz_Test } from "./Fuzz.t.sol";

contract MerkleInstant_Fuzz_Test is Shared_Fuzz_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                        TEST
    //////////////////////////////////////////////////////////////////////////*/

    function testFuzz_MerkleInstant(
        Allocation[] memory allocation,
        uint128 clawbackAmount,
        uint256 feeForUser,
        bool enabled,
        uint40 expiration,
        uint256[] memory indexesToClaim,
        uint256 msgValue,
        uint40 timeJumpSeed
    )
        external
    {
        // Ensure that merkle data is not empty.
        vm.assume(allocation.length > 0 && indexesToClaim.length < allocation.length);

        // Set the custom fee if enabled.
        feeForUser = enabled ? setCustomFee(merkleFactoryInstant, feeForUser) : MINIMUM_FEE;

        // Generate merkle root for the given allocation data.
        (uint256 aggregateAmount, bytes32 merkleRoot) = generateMerkleRoot(allocation);

        // Create the MerkleInstant campaign.
        _createMerkleInstant(aggregateAmount, expiration, feeForUser, merkleRoot);

        firstClaimTime = getBlockTimestamp();

        // Claim the airdrop for the given indexes.
        _claimAirdrops(indexesToClaim, msgValue, timeJumpSeed);

        // Clawback funds.
        clawback(merkleInstant, clawbackAmount);

        // Collect fees earned.
        collectFee(merkleFactoryInstant, merkleInstant);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CREATE-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function _createMerkleInstant(
        uint256 aggregateAmount,
        uint40 expiration,
        uint256 feeForUser,
        bytes32 merkleRoot
    )
        private
        givenCampaignNotExists
        whenTotalPercentageNotGreaterThan100
    {
        // Bound expiration so that the campaign is still active at the block time.
        if (expiration > 0) expiration = boundUint40(expiration, getBlockTimestamp() + 365 days, MAX_UNIX_TIMESTAMP);

        // Set campaign creator as the caller.
        resetPrank(users.campaignCreator);

        MerkleInstant.ConstructorParams memory params =
            merkleInstantConstructorParams(users.campaignCreator, expiration);
        params.merkleRoot = merkleRoot;

        // Get CREATE2 address of the campaign.
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

        // Verify that the contract is deployed at the correct address.
        assertGt(address(merkleInstant).code.length, 0, "MerkleInstant contract not created");
        assertEq(
            address(merkleInstant), expectedMerkleInstant, "MerkleInstant contract does not match computed address"
        );

        // Verify the campaign's expiration state.
        bool isExpired = expiration > 0 && expiration <= block.timestamp ? true : false;
        assertEq(merkleInstant.hasExpired(), isExpired, "isExpired");

        // Fund the MerkleInstant contract.
        deal({ token: address(dai), to: address(merkleInstant), give: aggregateAmount });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CLAIM-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function _claimAirdrops(
        uint256[] memory indexesToClaim,
        uint256 msgValue,
        uint40 timeJumpSeed
    )
        private
        givenMsgValueNotLessThanFee
    {
        for (uint256 i; i < indexesToClaim.length; ++i) {
            // Bound lead index so its valid.
            uint256 leafIndex = bound(indexesToClaim[i], 0, allotment.length - 1);

            Allocation memory allocation = allotment[leafIndex];

            // Claim the airdrop if it has not been claimed.
            if (!merkleInstant.hasClaimed(allocation.index)) {
                // Bound msgValue so that its greater than the minimum fee.
                msgValue = bound(msgValue, merkleInstant.minimumFeeInWei(), 100 ether);

                resetPrank(users.recipient);
                vm.deal(users.recipient, msgValue);

                vm.expectEmit({ emitter: address(merkleInstant) });
                emit ISablierMerkleInstant.Claim(allocation.index, allocation.recipient, allocation.amount);

                expectCallToTransfer({ token: dai, to: allocation.recipient, value: allocation.amount });

                bytes32[] memory merkleProof = computerMerkleProof(allocation);

                // Claim the airdrop.
                merkleInstant.claim{ value: msgValue }({
                    index: allocation.index,
                    recipient: allocation.recipient,
                    amount: allocation.amount,
                    merkleProof: merkleProof
                });

                // Assert that the claim has been made.
                assertTrue(merkleInstant.hasClaimed(allocation.index));

                // Update the fee earned.
                feeEarned += msgValue;

                // Warp to a new time.
                timeJumpSeed = boundUint40(timeJumpSeed, 0, 7 days);
                vm.warp(getBlockTimestamp() + timeJumpSeed);

                // Break loop if the campaign has expired.
                if (merkleInstant.EXPIRATION() > 0 && getBlockTimestamp() >= merkleInstant.EXPIRATION()) {
                    break;
                }
            }
        }
    }
}
