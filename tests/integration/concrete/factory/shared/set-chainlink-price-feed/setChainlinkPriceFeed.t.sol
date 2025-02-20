// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Integration_Test } from "./../../../../Integration.t.sol";

abstract contract SetChainlinkPriceFeed_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactoryBase.setChainlinkPriceFeed(AggregatorV3Interface(address(0)));
    }

    function test_WhenCallerAdmin() external {
        resetPrank({ msgSender: users.admin });
        assertEq(address(merkleFactoryBase.chainlinkPriceFeed()), address(chainlinkPriceFeedMock), "price feed before");
        merkleFactoryBase.setChainlinkPriceFeed(AggregatorV3Interface(address(0)));
        assertEq(address(merkleFactoryBase.chainlinkPriceFeed()), address(0), "price feed after");
    }
}
