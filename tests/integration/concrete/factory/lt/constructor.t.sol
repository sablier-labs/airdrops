// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleFactoryLT } from "src/SablierMerkleFactoryLT.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Constructor_MerkleFactoryLT_Integration_Test is Integration_Test {
    function test_Constructor() external {
        SablierMerkleFactoryLT constructedFactoryLT =
            new SablierMerkleFactoryLT(users.admin, address(chainlinkPriceFeedMock), MINIMUM_FEE);

        assertEq(constructedFactoryLT.admin(), users.admin, "factory admin");
        assertEq(constructedFactoryLT.chainlinkPriceFeed(), address(chainlinkPriceFeedMock), "price feed");
        assertEq(constructedFactoryLT.minimumFee(), MINIMUM_FEE, "minimum fee");
    }
}
