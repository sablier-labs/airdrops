// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";

import { Shared_Fuzz_Test } from "../Fuzz.t.sol";

contract SetCustomFee_Fuzz_Test is Shared_Fuzz_Test {
    function testFuzz_SetCustomFee(
        address campaignCreator,
        uint256 customFee
    )
        external
        whenCallerAdmin
        whenNewFeeNotExceedMaxFee
        testAcrossAllFactories
    {
        vm.assume(customFee <= MAX_FEE);

        // Check that get fee returns minimum fee for campaign creator.
        assertEq(merkleFactoryBase.getFee(campaignCreator), merkleFactoryBase.minimumFee(), "getFee != minimum fee");

        // It should emit a {SetCustomFee} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.SetCustomFee({
            admin: users.admin,
            campaignCreator: campaignCreator,
            customFee: customFee
        });

        merkleFactoryBase.setCustomFee(campaignCreator, customFee);

        // Get fee should return custom fee for campaign creator.
        assertEq(merkleFactoryBase.getFee(campaignCreator), customFee, "custom fee");
    }
}
