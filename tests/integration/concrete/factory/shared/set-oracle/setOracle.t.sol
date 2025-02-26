// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ChainlinkPriceFeedMock, ChainlinkPriceFeedMock_Zero } from "src/tests/ChainlinkPriceFeedMock.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract SetOracle_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactoryBase.setOracle(address(0));
    }

    function test_WhenCallerAdmin() external {
        resetPrank({ msgSender: users.admin });
    }

    function test_WhenNewPriceFeedZeroAddress() external whenCallerAdmin {
        resetPrank({ msgSender: users.admin });

        assertNotEq(merkleFactoryBase.oracle(), address(0), "oracle before");

        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.SetOracle(users.admin, address(0), address(oracle));
        merkleFactoryBase.setOracle(address(0));

        assertEq(merkleFactoryBase.oracle(), address(0), "oracle after");
    }

    modifier whenNewPriceFeedNotZeroAddress() {
        _;
    }

    function test_RevertWhen_NewPriceFeedReturnsZeroPrice() external whenCallerAdmin whenNewPriceFeedNotZeroAddress {
        ChainlinkPriceFeedMock_Zero newOracle = new ChainlinkPriceFeedMock_Zero();
        resetPrank({ msgSender: users.admin });

        merkleFactoryBase.setOracle(address(newOracle));
    }

    function test_WhenNewPriceFeedReturnsNonZeroPrice() external whenCallerAdmin whenNewPriceFeedNotZeroAddress {
        // Deploy a new Chainlink price feed contract that returns a constant price of $3000 for 1 native token.
        ChainlinkPriceFeedMock newOracle = new ChainlinkPriceFeedMock();

        resetPrank({ msgSender: users.admin });

        assertNotEq(merkleFactoryBase.oracle(), address(newOracle), "oracle before");

        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.SetOracle(users.admin, address(newOracle), address(oracle));
        merkleFactoryBase.setOracle(address(newOracle));

        assertEq(merkleFactoryBase.oracle(), address(newOracle), "oracle after");
    }
}
