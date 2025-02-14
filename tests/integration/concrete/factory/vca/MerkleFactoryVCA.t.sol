// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { Integration_Test } from "./../../../Integration.t.sol";
import { CollectFees_Integration_Test } from "./../shared/collect-fees/collectFees.t.sol";
import { GetFee_Integration_Test } from "./../shared/get-fee/getFee.t.sol";
import { ResetCustomFee_Integration_Test } from "./../shared/reset-custom-fee/resetCustomFee.t.sol";
import { SetCustomFee_Integration_Test } from "./../shared/set-custom-fee/setCustomFee.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                             NON-SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

abstract contract MerkleFactoryVCA_Integration_Shared_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {merkleFactoryVCA} contract as {ISablierMerkleFactoryBase}
        merkleFactoryBase = ISablierMerkleFactoryBase(merkleFactoryVCA);

        // Set the `merkleBase` to the merkleVCA contract to use it in the tests.
        merkleBase = ISablierMerkleBase(merkleVCA);

        // Claim to collect some fees.
        resetPrank(users.recipient);
        claim();
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract CollectFees_MerkleFactoryVCA_Integration_Test is
    MerkleFactoryVCA_Integration_Shared_Test,
    CollectFees_Integration_Test
{
    function setUp() public override(MerkleFactoryVCA_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryVCA_Integration_Shared_Test.setUp();
    }
}

contract GetFee_MerkleFactoryVCA_Integration_Test is
    MerkleFactoryVCA_Integration_Shared_Test,
    GetFee_Integration_Test
{
    function setUp() public override(MerkleFactoryVCA_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryVCA_Integration_Shared_Test.setUp();
    }
}

contract ResetCustomFee_MerkleFactoryVCA_Integration_Test is
    MerkleFactoryVCA_Integration_Shared_Test,
    ResetCustomFee_Integration_Test
{
    function setUp() public override(MerkleFactoryVCA_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryVCA_Integration_Shared_Test.setUp();
    }
}

contract SetCustomFee_MerkleFactoryVCA_Integration_Test is
    MerkleFactoryVCA_Integration_Shared_Test,
    SetCustomFee_Integration_Test
{
    function setUp() public override(MerkleFactoryVCA_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryVCA_Integration_Shared_Test.setUp();
    }
}
