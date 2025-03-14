// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";
import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleBuilder } from "../../utils/MerkleBuilder.sol";
import { Integration_Test } from "../Integration.t.sol";

/// @notice Common logic needed by all fuzz tests.
contract Shared_Fuzz_Test is Integration_Test {
    using MerkleBuilder for uint256[];

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE-VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    // Struct to store the airdrop allocation data for the test.
    struct Allocation {
        uint256 index;
        address recipient;
        uint128 amount;
    }

    // Storing leaves as `uint256`in storage so that we can use OpenZeppelin's {Arrays.findUpperBound}.
    uint256[] internal leaves;

    // Storing airdrop allotment in storage so that we can use it across functions.
    Allocation[] internal allotment;

    // Store the first claim time to be used in clawback.
    uint40 internal firstClaimTime;

    // Track claim fee earned in native tokens.
    uint256 internal feeEarned;

    /*//////////////////////////////////////////////////////////////////////////
                             COMMON-CAMPAIGN-FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function prepareCommonCreateParmas(
        Allocation[] memory allocation,
        uint256 indexesLength,
        uint256 feeForUser,
        bool enableCustomFee,
        uint40 expiration
    )
        internal
        returns (uint256 feeForUser_, uint40 expiration_, uint256 aggregateAmount, bytes32 merkleRoot)
    {
        vm.assume(allocation.length > 0 && indexesLength < allocation.length);

        // Bound expiration so that the campaign is still active at the creation.
        if (expiration > 0) expiration_ = boundUint40(expiration, getBlockTimestamp() + 365 days, MAX_UNIX_TIMESTAMP);

        // Set the custom fee if enabled.
        feeForUser_ = enableCustomFee ? testSetCustomFee(feeForUser) : MINIMUM_FEE;

        // Construct merkle root for the given allocation data.
        (aggregateAmount, merkleRoot) = constructMerkleTree(allocation);
    }

    // Helper function to test claiming multiple airdrops.
    function testClaimMultipleAirdrops(
        uint256[] memory indexesToClaim,
        uint256 msgValue
    )
        internal
        givenMsgValueNotLessThanFee
    {
        firstClaimTime = getBlockTimestamp();

        for (uint256 i; i < indexesToClaim.length; ++i) {
            // Bound lead index so its valid.
            uint256 leafIndex = bound(indexesToClaim[i], 0, allotment.length - 1);

            Allocation memory allocation = allotment[leafIndex];

            // Claim the airdrop if it has not been claimed.
            if (!merkleBase.hasClaimed(allotment[leafIndex].index)) {
                // Bound msgValue so that its greater than the minimum fee.
                msgValue = bound(msgValue, merkleBase.minimumFeeInWei(), 100 ether);

                address caller = makeAddr("philanthropist");
                resetPrank(caller);
                vm.deal(caller, msgValue);

                // Call the expect claim event function, implemented by the child contract.
                expectClaimEvent(allocation);

                bytes32[] memory merkleProof = computeMerkleProof(allocation);

                // Claim the airdrop.
                merkleBase.claim{ value: msgValue }({
                    index: allocation.index,
                    recipient: allocation.recipient,
                    amount: allocation.amount,
                    merkleProof: merkleProof
                });

                // It should mark the allocation as claimed.
                assertTrue(merkleBase.hasClaimed(allocation.index));

                // Update the fee earned.
                feeEarned += msgValue;

                // Warp to a new time.
                uint40 timeJumpSeed = uint40(uint256(keccak256(abi.encode(allocation))));
                timeJumpSeed = boundUint40(timeJumpSeed, 0, 7 days);
                vm.warp(getBlockTimestamp() + timeJumpSeed);

                // Break loop if the campaign has expired.
                if (merkleBase.EXPIRATION() > 0 && getBlockTimestamp() >= merkleBase.EXPIRATION()) {
                    break;
                }
            }
        }
    }

    // Helper function to test clawbacking funds.
    function testClawback(uint128 amount) internal {
        amount = boundUint128(amount, 0, uint128(dai.balanceOf(address(merkleBase))));

        resetPrank(users.campaignCreator);

        // It should emit event if the campaign has not expired or is within the grace period of 7 days.
        if (merkleBase.EXPIRATION() > 0 || getBlockTimestamp() <= firstClaimTime + 7 days) {
            vm.warp(merkleBase.EXPIRATION());

            expectCallToTransfer({ token: dai, to: users.campaignCreator, value: amount });
            vm.expectEmit({ emitter: address(merkleBase) });
            emit ISablierMerkleBase.Clawback({ to: users.campaignCreator, admin: users.campaignCreator, amount: amount });
        }
        // It should revert otherwise.
        else {
            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.SablierMerkleBase_ClawbackNotAllowed.selector,
                    getBlockTimestamp(),
                    merkleBase.EXPIRATION(),
                    firstClaimTime
                )
            );
        }

        // Clawback the funds.
        merkleBase.clawback({ to: users.campaignCreator, amount: amount });
    }

    // Helper function to test collecting fees earned.
    function testCollectFees() internal {
        // Load the initial ETH balance of the admin.
        uint256 initialAdminBalance = users.admin.balance;

        // collect the fees earned.
        merkleFactoryBase.collectFees(merkleBase);

        // It should decrease merkle contract balance to zero.
        assertEq(address(merkleBase).balance, 0, "merkle base ETH balance");

        // It should transfer fee to the factory admin.
        assertEq(users.admin.balance, initialAdminBalance + feeEarned, "admin ETH balance");
    }

    // Helper function to expect claim event. This function should be overridden in the child contract.
    function expectClaimEvent(Allocation memory allocation) internal virtual { }

    // Helper function to test setting custom fee.
    function testSetCustomFee(uint256 newFee) internal returns (uint256 feeForUser) {
        // Bound the custom fee between 0 and MAX_FEE.
        feeForUser = bound(newFee, 0, MAX_FEE);

        resetPrank(users.admin);
        merkleFactoryBase.setCustomFee(users.campaignCreator, feeForUser);
        assertEq(merkleFactoryBase.getFee(users.campaignCreator), feeForUser, "custom fee");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleProof(Allocation memory allocation) internal view returns (bytes32[] memory merkleProof) {
        uint256 leafToClaim = MerkleBuilder.computeLeaf(allocation.index, allocation.recipient, allocation.amount);
        uint256 leafPos = Arrays.findUpperBound(leaves, leafToClaim);

        merkleProof = leaves.length == 1 ? new bytes32[](0) : getProof(leaves.toBytes32(), leafPos);
    }

    function constructMerkleTree(Allocation[] memory allocation)
        internal
        returns (uint256 aggregateAmount, bytes32 merkleRoot)
    {
        uint128[] memory amounts = new uint128[](allocation.length);
        uint256[] memory indexes = new uint256[](allocation.length);
        address[] memory recipients = new address[](allocation.length);

        // Generate Merkle data with the given allocation data.
        for (uint256 i = 0; i < allocation.length; ++i) {
            indexes[i] = allocation[i].index;
            // Avoid zero recipient addresses.
            allocation[i].recipient =
                address(uint160(bound(uint256(uint160(allocation[i].recipient)), 1, type(uint160).max)));
            recipients[i] = allocation[i].recipient;

            // Bound each leaf amount so that `aggregateAmount` does not overflow.
            allocation[i].amount = boundUint128(allocation[i].amount, 1, uint128(MAX_UINT128 / allocation.length - 1));
            amounts[i] = allocation[i].amount;
            aggregateAmount += allocation[i].amount;

            // Store the allotment in storage.
            allotment.push(allocation[i]);
        }

        // Compute the Merkle leaves.
        leaves = new uint256[](allocation.length);
        leaves = MerkleBuilder.computeLeaves(indexes, recipients, amounts);

        // Sort the leaves in ascending order to match the production environment.
        leaves.sortLeaves();

        // If there is only one leaf, the Merkle root is the hash of the leaf itself.
        merkleRoot = leaves.length == 1 ? bytes32(leaves[0]) : getRoot(leaves.toBytes32());
    }
}
