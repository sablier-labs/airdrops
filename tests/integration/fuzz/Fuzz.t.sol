// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { Errors } from "src/libraries/Errors.sol";
import { LeafData, MerkleBuilder } from "../../utils/MerkleBuilder.sol";
import { Integration_Test } from "../Integration.t.sol";

/// @notice Common logic needed by all fuzz tests.
contract Shared_Fuzz_Test is Integration_Test {
    using MerkleBuilder for uint256[];

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE-VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    // Track claim fee earned in native tokens.
    uint256 internal feeEarned;

    // Store the first claim time to be used in clawback.
    uint40 internal firstClaimTime;

    // Storing leaves as `uint256`in storage so that we can use OpenZeppelin's {Arrays.findUpperBound}.
    uint256[] internal leaves;

    // Storing leaves data in storage so that we can use it across functions.
    LeafData[] internal leavesData;

    /*//////////////////////////////////////////////////////////////////////////
                             COMMON-CAMPAIGN-FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function prepareCommonCreateParams(
        LeafData[] memory rawLeavesData,
        uint40 expiration,
        uint256 indexesCount
    )
        internal
        returns (uint256 aggregateAmount, uint40 expiration_, bytes32 merkleRoot)
    {
        vm.assume(rawLeavesData.length > 0 && indexesCount < rawLeavesData.length);

        // Bound expiration so that the campaign is still active at the creation.
        if (expiration > 0) expiration_ = boundUint40(expiration, getBlockTimestamp() + 365 days, MAX_UNIX_TIMESTAMP);

        // Construct merkle root for the given tree leaves.
        (aggregateAmount, merkleRoot) = constructMerkleTree(rawLeavesData);
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
            uint256 leafIndex = bound(indexesToClaim[i], 0, leavesData.length - 1);

            LeafData memory leafData = leavesData[leafIndex];

            // Claim the airdrop if it has not been claimed.
            if (!merkleBase.hasClaimed(leavesData[leafIndex].index)) {
                // Bound msgValue so that its greater than the minimum fee.
                msgValue = bound(msgValue, merkleBase.minimumFeeInWei(), 100 ether);

                address caller = makeAddr("philanthropist");
                resetPrank(caller);
                vm.deal(caller, msgValue);

                // Call the expect claim event function, implemented by the child contract.
                expectClaimEvent(leafData);

                bytes32[] memory merkleProof = computeMerkleProof(leafData, leaves);

                // Claim the airdrop.
                merkleBase.claim{ value: msgValue }({
                    index: leafData.index,
                    recipient: leafData.recipient,
                    amount: leafData.amount,
                    merkleProof: merkleProof
                });

                // It should mark the leaf index as claimed.
                assertTrue(merkleBase.hasClaimed(leafData.index));

                // Update the fee earned.
                feeEarned += msgValue;

                // Warp to a new time.
                uint40 timeJumpSeed = uint40(uint256(keccak256(abi.encode(leafData))));
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
    function expectClaimEvent(LeafData memory leafData) internal virtual { }

    // Helper function to test setting custom fee.
    function testSetCustomFee(uint256 newFee) internal returns (uint256 feeForUser) {
        feeForUser = bound(newFee, 0, MAX_FEE_USD);

        resetPrank(users.admin);
        merkleFactoryBase.setCustomFee(users.campaignCreator, feeForUser);
        assertEq(merkleFactoryBase.getFee(users.campaignCreator), feeForUser, "custom fee");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function constructMerkleTree(LeafData[] memory rawLeavesData)
        internal
        returns (uint256 aggregateAmount, bytes32 merkleRoot)
    {
        // Fuzz the leaves data.
        aggregateAmount = fuzzMerkleData(rawLeavesData);

        // Store the merkle tree leaves in storage.
        for (uint256 i = 0; i < rawLeavesData.length; ++i) {
            leavesData.push(rawLeavesData[i]);
        }

        // Compute the Merkle leaves.
        MerkleBuilder.computeLeaves(leaves, rawLeavesData);

        // If there is only one leaf, the Merkle root is the hash of the leaf itself.
        merkleRoot = leaves.length == 1 ? bytes32(leaves[0]) : getRoot(leaves.toBytes32());
    }
}
