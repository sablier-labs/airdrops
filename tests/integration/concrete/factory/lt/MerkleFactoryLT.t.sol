// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { Integration_Test } from "./../../../Integration.t.sol";
import { CollectFees_Integration_Test } from "./../shared/collect-fees/collectFees.t.sol";
import { GetMinimumFeeFor_Integration_Test } from "./../shared/get-minimum-fee-for/getMinimumFeeFor.t.sol";
import { GetMinimumFee_Integration_Test } from "./../shared/get-minimum-fee/getMinimumFee.t.sol";
import { ResetCustomFee_Integration_Test } from "./../shared/reset-custom-fee/resetCustomFee.t.sol";
import { SetChainlinkPriceFeed_Integration_Test } from
    "./../shared/set-chainlink-price-feed/setChainlinkPriceFeed.t.sol";
import { SetCustomFee_Integration_Test } from "./../shared/set-custom-fee/setCustomFee.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                             NON-SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

abstract contract MerkleFactoryLT_Integration_Shared_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {merkleFactoryLT} contract as {ISablierMerkleFactoryBase}
        merkleFactoryBase = ISablierMerkleFactoryBase(merkleFactoryLT);

        // Set the `merkleBase` to the merkleLT contract to use it in the tests.
        merkleBase = ISablierMerkleBase(merkleLT);

        // Claim to collect some fees.
        resetPrank(users.recipient);
        claim();
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract CollectFees_MerkleFactoryLT_Integration_Test is
    MerkleFactoryLT_Integration_Shared_Test,
    CollectFees_Integration_Test
{
    function setUp() public override(MerkleFactoryLT_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryLT_Integration_Shared_Test.setUp();
    }
}

contract GetMinimumFee_MerkleFactoryLT_Integration_Test is
    MerkleFactoryLT_Integration_Shared_Test,
    GetMinimumFee_Integration_Test
{
    function setUp() public override(MerkleFactoryLT_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryLT_Integration_Shared_Test.setUp();
    }
}

contract GetMinimumFeeFor_MerkleFactoryLT_Integration_Test is
    MerkleFactoryLT_Integration_Shared_Test,
    GetMinimumFeeFor_Integration_Test
{
    function setUp() public override(MerkleFactoryLT_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryLT_Integration_Shared_Test.setUp();
    }
}

contract ResetCustomFee_MerkleFactoryLT_Integration_Test is
    MerkleFactoryLT_Integration_Shared_Test,
    ResetCustomFee_Integration_Test
{
    function setUp() public override(MerkleFactoryLT_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryLT_Integration_Shared_Test.setUp();
    }
}

contract SetCustomFee_MerkleFactoryLT_Integration_Test is
    MerkleFactoryLT_Integration_Shared_Test,
    SetCustomFee_Integration_Test
{
    function setUp() public override(MerkleFactoryLT_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryLT_Integration_Shared_Test.setUp();
    }
}

contract SetChainlinkPriceFeed_MerkleFactoryLT_Integration_Test is
    MerkleFactoryLT_Integration_Shared_Test,
    SetChainlinkPriceFeed_Integration_Test
{
    function setUp() public override(MerkleFactoryLT_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryLT_Integration_Shared_Test.setUp();
    }
}
