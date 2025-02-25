// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { Integration_Test } from "../../../Integration.t.sol";
import { CalculateMinimumFeeInWei_Integration_Test } from
    "./../shared/calculate-minimum-fee-in-wei/calculateMinimumFeeInWei.t.sol";
import { Clawback_Integration_Test } from "./../shared/clawback/clawback.t.sol";
import { CollectFees_Integration_Test } from "./../shared/collect-fees/collectFees.t.sol";
import { GetFirstClaimTime_Integration_Test } from "./../shared/get-first-claim-time/getFirstClaimTime.t.sol";
import { HasClaimed_Integration_Test } from "./../shared/has-claimed/hasClaimed.t.sol";
import { HasExpired_Integration_Test } from "./../shared/has-expired/hasExpired.t.sol";
import { SetMinimumFeeToZero_Integration_Test } from "./../shared/set-minimum-fee-to-zero/setMinimumFeeToZero.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                             NON-SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

abstract contract MerkleVCA_Integration_Shared_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {MerkleFactoryVCA} contract as {ISablierMerkleFactoryBase}
        merkleFactoryBase = ISablierMerkleFactoryBase(merkleFactoryVCA);

        // Cast the {MerkleVCA} contract as {ISablierMerkleBase}
        merkleBase = ISablierMerkleBase(merkleVCA);
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract CalculateMinimumFeeInWei_MerkleVCA_Integration_Test is
    MerkleVCA_Integration_Shared_Test,
    CalculateMinimumFeeInWei_Integration_Test("vca")
{
    function setUp() public override(MerkleVCA_Integration_Shared_Test, Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
    }
}

contract Clawback_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test, Clawback_Integration_Test {
    function setUp() public override(MerkleVCA_Integration_Shared_Test, Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
    }
}

contract CollectFees_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test, CollectFees_Integration_Test {
    function setUp() public override(MerkleVCA_Integration_Shared_Test, Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
    }
}

contract GetFirstClaimTime_MerkleVCA_Integration_Test is
    MerkleVCA_Integration_Shared_Test,
    GetFirstClaimTime_Integration_Test
{
    function setUp() public override(MerkleVCA_Integration_Shared_Test, Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
    }
}

contract HasClaimed_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test, HasClaimed_Integration_Test {
    function setUp() public override(MerkleVCA_Integration_Shared_Test, Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
    }
}

contract HasExpired_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test, HasExpired_Integration_Test {
    function setUp() public override(MerkleVCA_Integration_Shared_Test, Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
    }
}

contract SetMinimumFeeToZero_MerkleVCA_Integration_Test is
    MerkleVCA_Integration_Shared_Test,
    SetMinimumFeeToZero_Integration_Test
{
    function setUp() public override(MerkleVCA_Integration_Shared_Test, Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
    }
}
