// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierFactoryMerkleInstant } from "src/SablierFactoryMerkleInstant.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Constructor_FactoryMerkleInstant_Integration_Test is Integration_Test {
    function test_Constructor() external {
        SablierFactoryMerkleInstant constructedFactory =
            new SablierFactoryMerkleInstant(users.admin, MIN_FEE_USD, address(oracle));

        // SablierFactoryMerkleBase
        assertEq(constructedFactory.admin(), users.admin, "factory admin");
        assertEq(constructedFactory.MAX_FEE_USD(), MAX_FEE_USD, "max fee USD");
        assertEq(constructedFactory.minFeeUSD(), MIN_FEE_USD, "min fee USD");
        assertEq(constructedFactory.oracle(), address(oracle), "oracle");
    }
}
