// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierFactoryMerkleBase } from "src/interfaces/ISablierFactoryMerkleBase.sol";
import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { Integration_Test } from "./../../../Integration.t.sol";
import { CollectFees_Integration_Test } from "./../shared/collect-fees/collectFees.t.sol";
import { DisableCustomFeeUSD_Integration_Test } from "./../shared/disable-custom-fee-usd/disableCustomFeeUSD.t.sol";
import { MinFeeUSDFor_Integration_Test } from "./../shared/min-fee-usd-for/minFeeUSDFor.t.sol";
import { SetCustomFeeUSD_Integration_Test } from "./../shared/set-custom-fee-usd/setCustomFeeUSD.t.sol";
import { SetMinFeeUSD_Integration_Test } from "./../shared/set-min-fee-usd/setMinFeeUSD.t.sol";
import { SetNativeToken_Integration_Test } from "./../shared/set-native-token/setNativeToken.t.sol";
import { SetOracle_Integration_Test } from "./../shared/set-oracle/setOracle.t.sol";
/*//////////////////////////////////////////////////////////////////////////
                             NON-SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

abstract contract MerkleFactoryLT_Integration_Shared_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {merkleFactoryLT} contract as {ISablierFactoryMerkleBase}
        merkleFactoryBase = ISablierFactoryMerkleBase(merkleFactoryLT);

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

contract DisableCustomFeeUSD_MerkleFactoryLT_Integration_Test is
    MerkleFactoryLT_Integration_Shared_Test,
    DisableCustomFeeUSD_Integration_Test
{
    function setUp() public override(MerkleFactoryLT_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryLT_Integration_Shared_Test.setUp();
    }
}

contract MinFeeUSDFor_MerkleFactoryLT_Integration_Test is
    MerkleFactoryLT_Integration_Shared_Test,
    MinFeeUSDFor_Integration_Test
{
    function setUp() public override(MerkleFactoryLT_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryLT_Integration_Shared_Test.setUp();
    }
}

contract SetCustomFeeUSD_MerkleFactoryLT_Integration_Test is
    MerkleFactoryLT_Integration_Shared_Test,
    SetCustomFeeUSD_Integration_Test
{
    function setUp() public override(MerkleFactoryLT_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryLT_Integration_Shared_Test.setUp();
    }
}

contract SetMinFeeUSD_MerkleFactoryLT_Integration_Test is
    MerkleFactoryLT_Integration_Shared_Test,
    SetMinFeeUSD_Integration_Test
{
    function setUp() public override(MerkleFactoryLT_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryLT_Integration_Shared_Test.setUp();
    }
}

contract SetNativeToken_MerkleFactoryLT_Integration_Test is
    MerkleFactoryLT_Integration_Shared_Test,
    SetNativeToken_Integration_Test
{
    function setUp() public override(MerkleFactoryLT_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryLT_Integration_Shared_Test.setUp();
    }
}

contract SetOracle_MerkleFactoryLT_Integration_Test is
    MerkleFactoryLT_Integration_Shared_Test,
    SetOracle_Integration_Test
{
    function setUp() public override(MerkleFactoryLT_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryLT_Integration_Shared_Test.setUp();
    }
}
