// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ChainlinkPriceFeedMock, ChainlinkPriceFeedMock_Zero } from "src/tests/ChainlinkPriceFeedMock.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract SetChainlinkPriceFeed_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactoryBase.setChainlinkPriceFeed(address(0));
    }

    function test_WhenCallerAdmin() external {
        resetPrank({ msgSender: users.admin });
    }

    function test_WhenNewPriceFeedZeroAddress() external whenCallerAdmin {
        resetPrank({ msgSender: users.admin });

        assertNotEq(merkleFactoryBase.chainlinkPriceFeed(), address(0), "price feed before");

        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.SetChainlinkPriceFeed(users.admin, address(0));
        merkleFactoryBase.setChainlinkPriceFeed(address(0));

        assertEq(merkleFactoryBase.chainlinkPriceFeed(), address(0), "price feed after");
    }

    modifier whenNewPriceFeedNotZeroAddress() {
        _;
    }

    function test_RevertWhen_NewPriceFeedReturnsZeroPrice() external whenCallerAdmin whenNewPriceFeedNotZeroAddress {
        ChainlinkPriceFeedMock_Zero newChainlinkPriceFeed = new ChainlinkPriceFeedMock_Zero();
        resetPrank({ msgSender: users.admin });
        vm.expectRevert(
            abi.encodeWithSelector(Errors.IncorrectChainlinkPriceFeed.selector, address(newChainlinkPriceFeed))
        );
        merkleFactoryBase.setChainlinkPriceFeed(address(newChainlinkPriceFeed));
    }

    function test_WhenNewPriceFeedReturnsNonZeroPrice() external whenCallerAdmin whenNewPriceFeedNotZeroAddress {
        // Deploy a new Chainlink price feed contract that returns a constant price of $3000 for 1 native token.
        ChainlinkPriceFeedMock newChainlinkPriceFeed = new ChainlinkPriceFeedMock();

        resetPrank({ msgSender: users.admin });

        assertNotEq(merkleFactoryBase.chainlinkPriceFeed(), address(newChainlinkPriceFeed), "price feed before");

        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.SetChainlinkPriceFeed(users.admin, address(newChainlinkPriceFeed));
        merkleFactoryBase.setChainlinkPriceFeed(address(newChainlinkPriceFeed));

        assertEq(merkleFactoryBase.chainlinkPriceFeed(), address(newChainlinkPriceFeed), "price feed after");
    }
}
