// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { Integration_Test } from "./../../../../Integration.t.sol";

abstract contract SetChainlinkPriceFeed_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactoryBase.setChainlinkPriceFeed(address(0));
    }

    function test_WhenCallerAdmin() external {
        resetPrank({ msgSender: users.admin });
        assertEq(merkleFactoryBase.chainlinkPriceFeed(), address(chainlinkPriceFeedMock), "price feed before");
        merkleFactoryBase.setChainlinkPriceFeed(address(0));
        assertEq(merkleFactoryBase.chainlinkPriceFeed(), address(0), "price feed after");
    }
}
