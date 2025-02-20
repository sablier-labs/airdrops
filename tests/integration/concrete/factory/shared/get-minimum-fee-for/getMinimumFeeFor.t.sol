// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract GetMinimumFeeFor_Integration_Test is Integration_Test {
    function test_GivenCustomFeeSet() external {
        resetPrank(users.admin);
        assertEq(merkleFactoryBase.getMinimumFeeFor(users.campaignOwner), MINIMUM_FEE, "fee before");
        merkleFactoryBase.setCustomFee(users.campaignOwner, MINIMUM_FEE - 1);
        assertEq(merkleFactoryBase.getMinimumFeeFor(users.campaignOwner), MINIMUM_FEE - 1, "fee after");
    }

    function test_GivenPriceFeedNotSet() external givenCustomFeeNotSet {
        resetPrank(users.admin);
        assertEq(merkleFactoryBase.getMinimumFeeFor(users.campaignOwner), MINIMUM_FEE, "fee before");
        merkleFactoryBase.setChainlinkPriceFeed(AggregatorV3Interface(address(0)));
        assertEq(merkleFactoryBase.getMinimumFeeFor(users.campaignOwner), 0, "fee after");
    }

    function test_GivenPriceFeedSet() external view givenCustomFeeNotSet {
        assertEq(merkleFactoryBase.getMinimumFeeFor(users.campaignOwner), MINIMUM_FEE, "fee");
    }
}
