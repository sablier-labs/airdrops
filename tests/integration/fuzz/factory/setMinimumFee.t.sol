// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";

import { Shared_Fuzz_Test } from "../Fuzz.t.sol";

contract SetMinimumFee_Fuzz_Test is Shared_Fuzz_Test {
    function testFuzz_SetMinimumFee(uint256 fee)
        external
        whenCallerAdmin
        whenNewFeeNotExceedMaxFee
        testAcrossAllFactories
    {
        vm.assume(fee <= MAX_FEE);

        // It should emit a {SetMinimumFee} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.SetMinimumFee({ admin: users.admin, minimumFee: fee });

        merkleFactoryBase.setMinimumFee(fee);

        // It should set the minimum fee.
        assertEq(merkleFactoryBase.minimumFee(), fee, "minimum fee");
    }
}
