// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract SetMinimumFeeToZero_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotFactoryAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleBase_CallerNotFactoryAdmin.selector, users.admin, users.eve)
        );
        merkleBase.setMinimumFeeToZero();
    }

    modifier whenCallerFactoryAdmin() {
        _;
    }

    function test_GivenMinimumFeeAlreadyZero() external whenCallerFactoryAdmin {
        resetPrank(users.admin);
        merkleBase.setMinimumFeeToZero();
        assertEq(merkleBase.minimumFee(), 0);
        merkleBase.setMinimumFeeToZero();
        assertEq(merkleBase.minimumFee(), 0);
    }

    function test_GivenMinimumFeeNotZero() external whenCallerFactoryAdmin {
        resetPrank(users.admin);
        vm.expectEmit({ emitter: address(merkleBase) });
        emit ISablierMerkleBase.SetMinimumFeeToZero(users.admin, MINIMUM_FEE);
        merkleBase.setMinimumFeeToZero();
        assertEq(merkleBase.minimumFee(), 0);
    }
}
