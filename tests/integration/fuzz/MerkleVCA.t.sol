// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactoryVCA } from "src/interfaces/ISablierMerkleFactoryVCA.sol";
import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { MerkleVCA } from "src/types/DataTypes.sol";

import { Shared_Fuzz_Test } from "./Fuzz.t.sol";

contract MerkleVCA_Fuzz_Test is Shared_Fuzz_Test {
    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - Fuzzed custom fee.
    /// - MerkleVCA campaign with fuzzed allocations, expiration, and unlock timestamps.
    /// - Finite (only in future) expiration.
    /// - Unlock start time in the past.
    /// - Claiming airdrops for multiple indexes with fuzzed claim fee.
    /// - Fuzzed clawback amount.
    /// - Collect fees earned.
    function testFuzz_MerkleVCA(
        Allocation[] memory allocation,
        uint128 clawbackAmount,
        uint256 feeForUser,
        bool enabled,
        uint40 expiration,
        uint256[] memory indexesToClaim,
        uint256 msgValue,
        MerkleVCA.Timestamps memory timestamps
    )
        external
    {
        // Ensure that allocation data is not empty.
        vm.assume(allocation.length > 0 && indexesToClaim.length < allocation.length);

        // Bound timestamps so that campaign start time is in the past and end time exceed start time.
        timestamps.start = boundUint40(timestamps.start, 1, getBlockTimestamp() - 1);
        timestamps.end = boundUint40(timestamps.end, timestamps.start + 1, getBlockTimestamp() + 365 days);

        // Bound expiration so that the campaign is still active at the block time.
        expiration = boundUint40(expiration, getBlockTimestamp() + 365 days + 1 weeks, MAX_UNIX_TIMESTAMP);

        // Set the custom fee if enabled.
        feeForUser = enabled ? setCustomFee(merkleFactoryVCA, feeForUser) : MINIMUM_FEE;

        // Generate merkle root for the given allocation data.
        (uint256 aggregateAmount, bytes32 merkleRoot) = generateMerkleRoot(allocation);

        // Create the MerkleVCA campaign.
        _createMerkleVCA(aggregateAmount, expiration, feeForUser, merkleRoot, timestamps);

        firstClaimTime = getBlockTimestamp();

        // Claim the airdrop for the given indexes.
        claimMultipleAirdrops(merkleVCA, indexesToClaim, msgValue);

        // Clawback funds.
        clawback(merkleVCA, clawbackAmount);

        // Collect fees earned.
        collectFee(merkleFactoryVCA, merkleVCA);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CREATE-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function _createMerkleVCA(
        uint256 aggregateAmount,
        uint40 expiration,
        uint256 feeForUser,
        bytes32 merkleRoot,
        MerkleVCA.Timestamps memory timestamps
    )
        private
        givenCampaignNotExists
    {
        // Set campaign creator as the caller.
        resetPrank(users.campaignCreator);

        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams(expiration);
        params.merkleRoot = merkleRoot;
        params.timestamps = timestamps;

        // Get CREATE2 address of the campaign.
        address expectedMerkleVCA = computeMerkleVCAAddress(params, users.campaignCreator);

        // Expect a {CreateMerkleVCA} event.
        vm.expectEmit({ emitter: address(merkleFactoryVCA) });
        emit ISablierMerkleFactoryVCA.CreateMerkleVCA({
            merkleVCA: ISablierMerkleVCA(expectedMerkleVCA),
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: allotment.length,
            fee: feeForUser,
            oracle: address(oracle)
        });

        // Create the campaign.
        merkleVCA = merkleFactoryVCA.createMerkleVCA(params, aggregateAmount, allotment.length);

        // Verify that the contract is deployed at the correct address.
        assertGt(address(merkleVCA).code.length, 0, "MerkleVCA contract not created");
        assertEq(address(merkleVCA), expectedMerkleVCA, "MerkleVCA contract does not match computed address");

        // It should return false for hasExpired.
        assertFalse(merkleVCA.hasExpired(), "isExpired");

        // It should set return the correct unlock schedule.
        assertEq(merkleVCA.timestamps().start, timestamps.start, "unlock start");
        assertEq(merkleVCA.timestamps().end, timestamps.end, "unlock end");

        // Fund the MerkleVCA contract.
        deal({ token: address(dai), to: address(merkleVCA), give: aggregateAmount });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CLAIM-EVENT-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function expectClaimEvents(Allocation memory allocation) internal override {
        MerkleVCA.Timestamps memory timestamps = merkleVCA.timestamps();

        // Calculate claimable amount based on the vesting schedule.
        uint256 claimableAmount = getBlockTimestamp() < timestamps.end
            ? (uint256(allocation.amount) * (getBlockTimestamp() - timestamps.start)) / (timestamps.end - timestamps.start)
            : allocation.amount;

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.Claim(
            allocation.index, allocation.recipient, uint128(claimableAmount), allocation.amount
        );

        // It should transfer the claimable amount to the recipient.
        expectCallToTransfer({ token: dai, to: allocation.recipient, value: claimableAmount });
    }
}
