// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { Integration_Test } from "./../../../Integration.t.sol";
import { CollectFees_Integration_Test } from "./../shared/collect-fees/collectFees.t.sol";
import { DisableCustomFeeUSD_Integration_Test } from "./../shared/disable-custom-fee-usd/disableCustomFeeUSD.t.sol";
import { GetFee_Integration_Test } from "./../shared/get-fee/getFee.t.sol";
import { SetCustomFeeUSD_Integration_Test } from "./../shared/set-custom-fee-usd/setCustomFeeUSD.t.sol";
import { SetMinFeeUSD_Integration_Test } from "./../shared/set-min-fee-usd/setMinFeeUSD.t.sol";
import { SetNativeToken_Integration_Test } from "./../shared/set-native-token/setNativeToken.t.sol";
import { SetOracle_Integration_Test } from "./../shared/set-oracle/setOracle.t.sol";
/*//////////////////////////////////////////////////////////////////////////
                             NON-SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

abstract contract MerkleFactoryLL_Integration_Shared_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {merkleFactoryLL} contract as {ISablierMerkleFactoryBase}
        merkleFactoryBase = ISablierMerkleFactoryBase(merkleFactoryLL);

        // Set the `merkleBase` to the merkleLL contract to use it in the tests.
        merkleBase = ISablierMerkleBase(merkleLL);

        // Claim to collect some fees.
        resetPrank(users.recipient);
        claim();
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract CollectFees_MerkleFactoryLL_Integration_Test is
    MerkleFactoryLL_Integration_Shared_Test,
    CollectFees_Integration_Test
{
    function setUp() public override(MerkleFactoryLL_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryLL_Integration_Shared_Test.setUp();
    }
}

contract GetFee_MerkleFactoryLL_Integration_Test is MerkleFactoryLL_Integration_Shared_Test, GetFee_Integration_Test {
    function setUp() public override(MerkleFactoryLL_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryLL_Integration_Shared_Test.setUp();
    }
}

contract DisableCustomFeeUSD_MerkleFactoryLL_Integration_Test is
    MerkleFactoryLL_Integration_Shared_Test,
    DisableCustomFeeUSD_Integration_Test
{
    function setUp() public override(MerkleFactoryLL_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryLL_Integration_Shared_Test.setUp();
    }
}

contract SetCustomFeeUSD_MerkleFactoryLL_Integration_Test is
    MerkleFactoryLL_Integration_Shared_Test,
    SetCustomFeeUSD_Integration_Test
{
    function setUp() public override(MerkleFactoryLL_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryLL_Integration_Shared_Test.setUp();
    }
}

contract SetMinFeeUSD_MerkleFactoryLL_Integration_Test is
    MerkleFactoryLL_Integration_Shared_Test,
    SetMinFeeUSD_Integration_Test
{
    function setUp() public override(MerkleFactoryLL_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryLL_Integration_Shared_Test.setUp();
    }
}

contract SetNativeToken_MerkleFactoryLL_Integration_Test is
    MerkleFactoryLL_Integration_Shared_Test,
    SetNativeToken_Integration_Test
{
    function setUp() public override(MerkleFactoryLL_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryLL_Integration_Shared_Test.setUp();
    }
}

contract SetOracle_MerkleFactoryLL_Integration_Test is
    MerkleFactoryLL_Integration_Shared_Test,
    SetOracle_Integration_Test
{
    function setUp() public override(MerkleFactoryLL_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryLL_Integration_Shared_Test.setUp();
    }
}
