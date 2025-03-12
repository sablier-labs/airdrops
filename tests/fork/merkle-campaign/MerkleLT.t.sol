// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Lockup } from "@sablier/lockup/src/types/DataTypes.sol";

import { ISablierMerkleFactoryLT } from "src/interfaces/ISablierMerkleFactoryLT.sol";
import { ISablierMerkleLockup } from "src/interfaces/ISablierMerkleLockup.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { MerkleLT } from "src/types/DataTypes.sol";

import { Fork_Test } from "./../Fork.t.sol";
import { MerkleBase_Fork_Test } from "./MerkleBase.t.sol";

abstract contract MerkleLT_Fork_Test is MerkleBase_Fork_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 tokenAddress) MerkleBase_Fork_Test(tokenAddress) { }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Fork_Test.setUp();

        // Cast the {merkleFactoryLT} contract as {ISablierMerkleFactoryBase}
        merkleFactoryBase = merkleFactoryLT;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST-FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function testForkFuzz_MerkleLT(Params memory params, uint40 startTime) external {
        /*//////////////////////////////////////////////////////////////////////////
                                          CREATE
        //////////////////////////////////////////////////////////////////////////*/

        uint40 expectedStartTime;

        // If the start time is not zero, bound it to a reasonable range so that vesting end time can be in the past,
        // present and future.
        if (startTime != 0) {
            startTime =
                boundUint40(startTime, getBlockTimestamp() - TOTAL_DURATION - 10 days, getBlockTimestamp() + 2 days);
            expectedStartTime = startTime;
        } else {
            expectedStartTime = getBlockTimestamp();
        }

        preCreateCampaign(params);

        MerkleLT.ConstructorParams memory constructorParams = merkleLTConstructorParams({
            campaignOwner: params.campaignOwner,
            expiration: params.expiration,
            lockupAddress: lockup,
            merkleRoot: vars.merkleRoot,
            startTime: startTime,
            tokenAddress: FORK_TOKEN
        });

        vars.expectedMerkleCampaign =
            computeMerkleLTAddress({ params: constructorParams, campaignCreator: params.campaignOwner });

        vm.expectEmit({ emitter: address(merkleFactoryLT) });
        emit ISablierMerkleFactoryLT.CreateMerkleLT({
            merkleLT: ISablierMerkleLT(vars.expectedMerkleCampaign),
            params: constructorParams,
            aggregateAmount: vars.aggregateAmount,
            recipientCount: vars.recipientCount,
            totalDuration: TOTAL_DURATION,
            fee: vars.minimumFee,
            oracle: vars.oracle
        });

        merkleLT = merkleFactoryLT.createMerkleLT(constructorParams, vars.aggregateAmount, vars.recipientCount);

        assertGt(address(merkleLT).code.length, 0, "MerkleLT contract not created");
        assertEq(address(merkleLT), vars.expectedMerkleCampaign, "MerkleLT contract does not match computed address");

        // Cast the {MerkleLT} contract as {ISablierMerkleBase}
        merkleBase = merkleLT;

        /*//////////////////////////////////////////////////////////////////////////
                                          CLAIM
        //////////////////////////////////////////////////////////////////////////*/

        preClaim(params);

        uint256 expectedStreamId;
        uint256 initialRecipientTokenBalance = FORK_TOKEN.balanceOf(vars.recipientToClaim);

        // It should emit {Claim} event based on the vesting end time.
        if (expectedStartTime + TOTAL_DURATION <= getBlockTimestamp()) {
            vm.expectEmit({ emitter: address(merkleLT) });
            emit ISablierMerkleLockup.Claim(vars.indexToClaim, vars.recipientToClaim, vars.amountToClaim);
            expectCallToTransfer({ token: FORK_TOKEN, to: vars.recipientToClaim, value: vars.amountToClaim });
        } else {
            expectedStreamId = lockup.nextStreamId();
            vm.expectEmit({ emitter: address(merkleLT) });
            emit ISablierMerkleLockup.Claim(
                vars.indexToClaim, vars.recipientToClaim, vars.amountToClaim, expectedStreamId
            );
        }

        expectCallToClaimWithData({
            merkleLockup: address(merkleLT),
            feeInWei: vars.minimumFeeInWei,
            index: vars.indexToClaim,
            recipient: vars.recipientToClaim,
            amount: vars.amountToClaim,
            merkleProof: vars.merkleProof
        });

        // Claim the airdrop.
        merkleLT.claim{ value: vars.minimumFeeInWei }({
            index: vars.indexToClaim,
            recipient: vars.recipientToClaim,
            amount: vars.amountToClaim,
            merkleProof: vars.merkleProof
        });

        // Assertions when vesting end time does not exceed the block time.
        if (expectedStartTime + TOTAL_DURATION <= getBlockTimestamp()) {
            assertEq(
                FORK_TOKEN.balanceOf(vars.recipientToClaim),
                initialRecipientTokenBalance + vars.amountToClaim,
                "recipient balance"
            );
        }
        // Assertions when vesting end time exceeds the block time.
        else {
            Lockup.CreateWithTimestamps memory expectedLockup = Lockup.CreateWithTimestamps({
                sender: params.campaignOwner,
                recipient: vars.recipientToClaim,
                depositAmount: vars.amountToClaim,
                token: FORK_TOKEN,
                cancelable: CANCELABLE,
                transferable: TRANSFERABLE,
                timestamps: Lockup.Timestamps({ start: expectedStartTime, end: expectedStartTime + TOTAL_DURATION }),
                shape: SHAPE
            });

            // Assert that the stream has been created successfully.
            assertEq(lockup, expectedStreamId, expectedLockup);
            assertEq(lockup.getLockupModel(expectedStreamId), Lockup.Model.LOCKUP_TRANCHED);
            assertEq(
                lockup.getTranches(expectedStreamId),
                tranchesMerkleLT({ streamStartTime: expectedStartTime, totalAmount: vars.amountToClaim })
            );

            uint256[] memory expectedClaimedStreamIds = new uint256[](1);
            expectedClaimedStreamIds[0] = expectedStreamId;
            assertEq(merkleLT.claimedStreams(vars.recipientToClaim), expectedClaimedStreamIds, "claimed streams");
        }

        // Assert that the claim has been made.
        assertTrue(merkleLT.hasClaimed(vars.indexToClaim));

        /*//////////////////////////////////////////////////////////////////////////
                                        CLAWBACK
        //////////////////////////////////////////////////////////////////////////*/

        testClawback(params);

        /*//////////////////////////////////////////////////////////////////////////
                                        COLLECT-FEES
        //////////////////////////////////////////////////////////////////////////*/

        testCollectFees();
    }
}
