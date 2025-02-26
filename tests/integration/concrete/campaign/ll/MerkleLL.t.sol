// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { Integration_Test } from "./../../../Integration.t.sol";
import { CalculateMinimumFeeInWei_Integration_Test } from
    "./../shared/calculate-minimum-fee-in-wei/calculateMinimumFeeInWei.t.sol";
import { Clawback_Integration_Test } from "./../shared/clawback/clawback.t.sol";
import { CollectFees_Integration_Test } from "./../shared/collect-fees/collectFees.t.sol";
import { GetFirstClaimTime_Integration_Test } from "./../shared/get-first-claim-time/getFirstClaimTime.t.sol";
import { HasClaimed_Integration_Test } from "./../shared/has-claimed/hasClaimed.t.sol";
import { HasExpired_Integration_Test } from "./../shared/has-expired/hasExpired.t.sol";
import { LowerMinimumFee_Integration_Test } from "./../shared/lower-minimum-fee/lowerMinimumFee.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                             NON-SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

abstract contract MerkleLL_Integration_Shared_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {merkleFactoryLL} contract as {ISablierMerkleFactoryBase}
        merkleFactoryBase = ISablierMerkleFactoryBase(merkleFactoryLL);

        // Cast the {MerkleLL} contract as {ISablierMerkleBase}
        merkleBase = ISablierMerkleBase(merkleLL);
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract CalculateMinimumFeeInWei_MerkleLL_Integration_Test is
    MerkleLL_Integration_Shared_Test,
    CalculateMinimumFeeInWei_Integration_Test("ll")
{
    function setUp() public override(MerkleLL_Integration_Shared_Test, Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
    }
}

contract Clawback_MerkleLL_Integration_Test is MerkleLL_Integration_Shared_Test, Clawback_Integration_Test {
    function setUp() public override(MerkleLL_Integration_Shared_Test, Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
    }
}

contract CollectFees_MerkleLL_Integration_Test is MerkleLL_Integration_Shared_Test, CollectFees_Integration_Test {
    function setUp() public override(MerkleLL_Integration_Shared_Test, Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
    }
}

contract GetFirstClaimTime_MerkleLL_Integration_Test is
    MerkleLL_Integration_Shared_Test,
    GetFirstClaimTime_Integration_Test
{
    function setUp() public override(MerkleLL_Integration_Shared_Test, Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
    }
}

contract HasClaimed_MerkleLL_Integration_Test is MerkleLL_Integration_Shared_Test, HasClaimed_Integration_Test {
    function setUp() public override(MerkleLL_Integration_Shared_Test, Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
    }
}

contract HasExpired_MerkleLL_Integration_Test is MerkleLL_Integration_Shared_Test, HasExpired_Integration_Test {
    function setUp() public override(MerkleLL_Integration_Shared_Test, Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
    }
}

contract LowerMinimumFee_MerkleLL_Integration_Test is
    MerkleLL_Integration_Shared_Test,
    LowerMinimumFee_Integration_Test
{
    function setUp() public override(MerkleLL_Integration_Shared_Test, Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
    }
}
