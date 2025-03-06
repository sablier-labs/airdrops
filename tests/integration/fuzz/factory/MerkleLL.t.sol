// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";
import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { ISablierMerkleFactoryLL } from "src/interfaces/ISablierMerkleFactoryLL.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLockup } from "src/interfaces/ISablierMerkleLockup.sol";
import { MerkleLL } from "src/types/DataTypes.sol";
import { MerkleBuilder } from "./../../../utils/MerkleBuilder.sol";
import { Integration_Test } from "./../../Integration.t.sol";

;

contract MerkleLL_Fuzz_Test is Integration_Test {
    using MerkleBuilder for uint256[];

    /// @dev Encapsulates the data needed to compute a Merkle tree leaf.
    struct Allocation {
        uint256 index;
        address recipient;
        uint128 amount;
    }

    // We need the leaves as a storage variable so that we can use OpenZeppelin's {Arrays.findUpperBound}.
    uint256[] internal leaves;

    // Storing merkle tree in storage so that we can use it across functions.
    Allocation[] internal leafData;

    function testFuzz_MerkleLL(
        uint256 customFee,
        bool enabled,
        uint40 expiration,
        uint256 leafIndex,
        Allocation[] memory allocation,
        uint256 msgValue,
        MerkleLL.Schedule memory schedule
    )
        external
    {
        // Ensure that merkle data is not empty.
        vm.assume(allocation.length > 0);

        // If enabled is true, set the custom fee.
        if (enabled) {
            // Bound the custom fee between 0 and MAX_FEE.
            customFee = bound(customFee, 0, MAX_FEE);

            // Enable the custom fee for this test.
            resetPrank(users.admin);
            merkleFactoryLL.setCustomFee(users.campaignCreator, customFee);

            // Get fee should return custom fee for campaign creator.
            assertEq(merkleFactoryBase.getFee(users.campaignCreator), customFee, "custom fee");
        }

        uint256 aggregateAmount;

        // Prepare recipients claim data for merkle tree.
        uint256 recipientCount = allocation.length;
        uint128[] memory amounts = new uint128[](recipientCount);
        uint256[] memory indexes = new uint256[](recipientCount);
        address[] memory recipients = new address[](recipientCount);
        for (uint256 i = 0; i < recipientCount; ++i) {
            indexes[i] = allocation[i].index;
            // Avoid zero recipient addresses.
            allocation[i].recipient =
                address(uint160(bound(uint256(uint160(allocation[i].recipient)), 1, type(uint160).max)));
            recipients[i] = allocation[i].recipient;

            // Bound each leaf amount so that `aggregateAmount` does not overflow.
            allocation[i].amount = boundUint128(allocation[i].amount, 1, uint128(MAX_UINT128 / recipientCount - 1));
            amounts[i] = allocation[i].amount;
            aggregateAmount += allocation[i].amount;

            // Store the merkle tree in storage.
            leafData.push(allocation[i]);
        }

        // Compute the merkle leaves..
        leaves = new uint256[](recipientCount);
        leaves = MerkleBuilder.computeLeaves(indexes, recipients, amounts);

        // Sort the leaves in ascending order to match the production environment.
        MerkleBuilder.sortLeaves(leaves);

        // If there is only one leaf, the Merkle root is the hash of the leaf itself.
        bytes32 merkleRoot = leaves.length == 1 ? bytes32(leaves[0]) : getRoot(leaves.toBytes32());

        uint256 feeForUser = enabled ? customFee : MINIMUM_FEE;

        _createMerkleLL(aggregateAmount, expiration, feeForUser, merkleRoot, schedule);

        // Fund the MerkleLL contract.
        deal({ token: address(dai), to: address(merkleLL), give: aggregateAmount });

        leafIndex = bound(leafIndex, 0, leafData.length - 1);

        _claim(leafIndex, msgValue);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        CREATE
    //////////////////////////////////////////////////////////////////////////*/

    function _createMerkleLL(
        uint256 aggregateAmount,
        uint40 expiration,
        uint256 feeForUser,
        bytes32 merkleRoot,
        MerkleLL.Schedule memory schedule
    )
        internal
        givenCampaignNotExists
        whenTotalPercentageNotGreaterThan100
    {
        expiration = boundUint40(expiration, getBlockTimestamp() + 1 seconds, MAX_UNIX_TIMESTAMP);

        schedule.startTime = boundUint40(schedule.startTime, 0, MAX_UNIX_TIMESTAMP - 1);
        uint40 expectedStartTime = schedule.startTime == 0 ? getBlockTimestamp() : schedule.startTime;
        schedule.cliffDuration = boundUint40(schedule.cliffDuration, 0, MAX_UNIX_TIMESTAMP - expectedStartTime - 1);
        schedule.totalDuration =
            boundUint40(schedule.totalDuration, schedule.cliffDuration + 1, MAX_UNIX_TIMESTAMP - expectedStartTime);

        // Bound unlock percentages so that the sum does not exceed 100%.
        schedule.startPercentage = _bound(schedule.startPercentage, 0, 1e18);
        schedule.cliffPercentage = schedule.cliffDuration > 0
            ? _bound(schedule.cliffPercentage, 0, 1e18 - schedule.startPercentage.unwrap())
            : ud2x18(0);

        // Set campaign creator as the caller.
        resetPrank(users.campaignCreator);

        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams(users.campaignCreator, expiration);
        params.schedule = schedule;
        params.merkleRoot = merkleRoot;

        // Get CREATE2 address of the campaign.
        address expectedMerkleLL = computeMerkleLLAddress(params, users.campaignCreator);

        // Expect a {CreateMerkleLL} event.
        vm.expectEmit({ emitter: address(merkleFactoryLL) });
        emit ISablierMerkleFactoryLL.CreateMerkleLL({
            merkleLL: ISablierMerkleLL(expectedMerkleLL),
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: leafData.length,
            fee: feeForUser,
            oracle: address(oracle)
        });

        // Create the campaign.
        merkleLL = merkleFactoryLL.createMerkleLL(params, aggregateAmount, leafData.length);

        // Verify that the contract is deployed at the correct address.
        assertGt(address(merkleLL).code.length, 0, "MerkleLL contract not created");
        assertEq(address(merkleLL), expectedMerkleLL, "MerkleLL contract does not match computed address");

        // Verify the campaign's expiration state.
        bool isExpired = expiration > 0 && expiration <= block.timestamp ? true : false;
        assertEq(merkleLL.hasExpired(), isExpired, "isExpired");

        // Verify campaign's schedule.
        MerkleLL.Schedule memory actualSchedule = merkleLL.getSchedule();
        assertEq(actualSchedule.startTime, schedule.startTime, "schedule.startTime");
        assertEq(actualSchedule.startPercentage, schedule.startPercentage, "schedule.startPercentage");
        assertEq(actualSchedule.cliffDuration, schedule.cliffDuration, "schedule.cliffDuration");
        assertEq(actualSchedule.cliffPercentage, schedule.cliffPercentage, "schedule.cliffPercentage");
        assertEq(actualSchedule.totalDuration, schedule.totalDuration, "schedule.totalDuration");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        CLAIM
    //////////////////////////////////////////////////////////////////////////*/

    function _claim(uint256 leafIndex, uint256 msgValue) internal givenMsgValueNotLessThanFee {
        // Bound msgValue so that its not less than the minimum fee.
        msgValue = bound(msgValue, merkleLL.minimumFeeInWei(), 100 ether);

        resetPrank({ msgSender: users.recipient });
        vm.deal(users.recipient, msgValue);

        // It should emit {Claim} event based on the vesting end time.
        MerkleLL.Schedule memory schedule = merkleLL.getSchedule();
        uint40 expectedStartTime = schedule.startTime == 0 ? getBlockTimestamp() : schedule.startTime;
        bool isDirectTransfer = expectedStartTime + schedule.totalDuration <= getBlockTimestamp() ? true : false;

        if (isDirectTransfer) {
            vm.expectEmit({ emitter: address(merkleLL) });
            emit ISablierMerkleLockup.Claim(
                leafData[leafIndex].index, leafData[leafIndex].recipient, leafData[leafIndex].amount
            );

            expectCallToTransfer({ token: dai, to: leafData[leafIndex].recipient, value: leafData[leafIndex].amount });
        } else {
            uint256 expectedStreamId = lockup.nextStreamId();
            vm.expectEmit({ emitter: address(merkleLL) });
            emit ISablierMerkleLockup.Claim(
                leafData[leafIndex].index, leafData[leafIndex].recipient, leafData[leafIndex].amount, expectedStreamId
            );
        }

        uint256 leafToClaim = MerkleBuilder.computeLeaf(
            leafData[leafIndex].index, leafData[leafIndex].recipient, leafData[leafIndex].amount
        );
        uint256 leafPos = Arrays.findUpperBound(leaves, leafToClaim);

        bytes32[] memory merkleProof = leaves.length == 1 ? new bytes32[](0) : getProof(leaves.toBytes32(), leafPos);

        // Claim the airdrop.
        merkleLL.claim{ value: msgValue }({
            index: leafData[leafIndex].index,
            recipient: leafData[leafIndex].recipient,
            amount: leafData[leafIndex].amount,
            merkleProof: merkleProof
        });

        // Assert that the claim has been made.
        assertTrue(merkleLL.hasClaimed(leafData[leafIndex].index));
    }
}
