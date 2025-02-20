// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract GetMinimumFee_Integration_Test is Integration_Test {
    function test_GivenPriceFeedNotSet() external {
        resetPrank({ msgSender: users.admin });
        merkleFactoryBase.setChainlinkPriceFeed({ newChainlinkPriceFeed: AggregatorV3Interface(address(0)) });
        assertEq(merkleFactoryBase.getMinimumFee(), 0, "minimum fee");
    }

    function test_GivenPriceFeedSet() external view {
        // It should return custom fee.
        assertEq(merkleFactoryBase.getMinimumFee(), MINIMUM_FEE, "custom fee");
    }
}
