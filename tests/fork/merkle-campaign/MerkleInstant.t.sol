// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierMerkleFactoryInstant } from "src/interfaces/ISablierMerkleFactoryInstant.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";

import { MerkleInstant } from "src/types/DataTypes.sol";

import { Fork_Test } from "./../Fork.t.sol";
import { MerkleBase_Fork_Test } from "./MerkleBase.t.sol";

abstract contract MerkleInstant_Fork_Test is MerkleBase_Fork_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 tokenAddress) MerkleBase_Fork_Test(tokenAddress) { }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Fork_Test.setUp();

        // Cast the {merkleFactoryInstant} contract as {ISablierMerkleFactoryBase}
        merkleFactoryBase = merkleFactoryInstant;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST-FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function testForkFuzz_MerkleInstant(Params memory params) external {
        /*//////////////////////////////////////////////////////////////////////////
                                          CREATE
        //////////////////////////////////////////////////////////////////////////*/

        preCreateCampaign(params);

        MerkleInstant.ConstructorParams memory constructorParams = merkleInstantConstructorParams({
            campaignOwner: params.campaignOwner,
            expiration: params.expiration,
            merkleRoot: vars.merkleRoot,
            tokenAddress: FORK_TOKEN
        });

        vars.expectedMerkleCampaign =
            computeMerkleInstantAddress({ params: constructorParams, campaignCreator: params.campaignOwner });

        vm.expectEmit({ emitter: address(merkleFactoryInstant) });
        emit ISablierMerkleFactoryInstant.CreateMerkleInstant({
            merkleInstant: ISablierMerkleInstant(vars.expectedMerkleCampaign),
            params: constructorParams,
            aggregateAmount: vars.aggregateAmount,
            recipientCount: vars.recipientCount,
            fee: vars.minimumFee,
            oracle: vars.oracle
        });

        merkleInstant =
            merkleFactoryInstant.createMerkleInstant(constructorParams, vars.aggregateAmount, vars.recipientCount);

        assertGt(address(merkleInstant).code.length, 0, "MerkleInstant contract not created");
        assertEq(
            address(merkleInstant),
            vars.expectedMerkleCampaign,
            "MerkleInstant contract does not match computed address"
        );

        // Cast the {MerkleInstant} contract as {ISablierMerkleBase}
        merkleBase = merkleInstant;

        /*//////////////////////////////////////////////////////////////////////////
                                          CLAIM
        //////////////////////////////////////////////////////////////////////////*/

        preClaim(params);

        expectCallToClaimWithData({
            merkleLockup: address(merkleInstant),
            feeInWei: vars.minimumFeeInWei,
            index: vars.indexToClaim,
            recipient: vars.recipients[params.posBeforeSort],
            amount: vars.amounts[params.posBeforeSort],
            merkleProof: vars.merkleProof
        });

        expectCallToTransfer({
            token: FORK_TOKEN,
            to: vars.recipients[params.posBeforeSort],
            value: vars.amounts[params.posBeforeSort]
        });

        merkleInstant.claim{ value: vars.minimumFeeInWei }({
            index: vars.indexToClaim,
            recipient: vars.recipients[params.posBeforeSort],
            amount: vars.amounts[params.posBeforeSort],
            merkleProof: vars.merkleProof
        });

        assertTrue(merkleInstant.hasClaimed(vars.indexToClaim));

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
