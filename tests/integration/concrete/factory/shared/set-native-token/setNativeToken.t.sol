// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { ISablierFactoryMerkleBase } from "src/interfaces/ISablierFactoryMerkleBase.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Integration_Test } from "./../../../../Integration.t.sol";

abstract contract SetNativeToken_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        setMsgSender({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.admin, users.eve));
        factoryMerkleBase.setNativeToken(address(dai));
    }

    function test_RevertWhen_ProvidedAddressZero() external whenCallerAdmin {
        address newNativeToken = address(0);

        vm.expectRevert(Errors.SablierFactoryMerkleBase_NativeTokenZeroAddress.selector);
        factoryMerkleBase.setNativeToken(newNativeToken);
    }

    function test_RevertGiven_NativeTokenAlreadySet() external whenCallerAdmin whenProvidedAddressNotZero {
        // Already set the native token for this test.
        address nativeToken = address(dai);
        factoryMerkleBase.setNativeToken(nativeToken);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFactoryMerkleBase_NativeTokenAlreadySet.selector, nativeToken)
        );

        // Set native token again with a different address.
        factoryMerkleBase.setNativeToken(address(usdc));
    }

    function test_GivenNativeTokenNotSet() external whenCallerAdmin whenProvidedAddressNotZero {
        address nativeToken = address(dai);

        // It should emit a {SetNativeToken} event.
        vm.expectEmit({ emitter: address(factoryMerkleBase) });
        emit ISablierFactoryMerkleBase.SetNativeToken({ admin: users.admin, nativeToken: nativeToken });

        // Set native token.
        factoryMerkleBase.setNativeToken(nativeToken);

        // It should set native token.
        assertEq(factoryMerkleBase.nativeToken(), nativeToken, "native token");
    }
}
