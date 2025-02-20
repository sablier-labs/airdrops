// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleFactoryLL } from "src/SablierMerkleFactoryLL.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Constructor_MerkleFactoryLL_Integration_Test is Integration_Test {
    function test_Constructor() external {
        SablierMerkleFactoryLL constructedFactoryLL =
            new SablierMerkleFactoryLL(users.admin, address(chainlinkPriceFeedMock));

        assertEq(constructedFactoryLL.admin(), users.admin, "factory admin");
        assertEq(address(constructedFactoryLL.chainlinkPriceFeed()), address(chainlinkPriceFeedMock), "price feed");
    }
}
