// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Integration_Test } from "./../../../../Integration.t.sol";

abstract contract SetMinFeeUSD_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactoryBase.setMinFeeUSD(0.001e18);
    }

    function test_RevertWhen_NewMinFeeExceedsMaxFee() external whenCallerAdmin {
        uint256 newMinFeeUSD = MAX_FEE_USD + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleFactoryBase_MaxFeeUSDExceeded.selector, newMinFeeUSD, MAX_FEE_USD
            )
        );
        merkleFactoryBase.setMinFeeUSD(newMinFeeUSD);
    }

    function test_WhenNewMinFeeNotExceedMaxFee() external whenCallerAdmin {
        uint256 newMinFeeUSD = MAX_FEE_USD;

        // It should emit a {SetMinFeeUSD} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.SetMinFeeUSD({
            admin: users.admin,
            newMinFeeUSD: newMinFeeUSD,
            previousMinFeeUSD: MIN_FEE_USD
        });

        merkleFactoryBase.setMinFeeUSD(newMinFeeUSD);

        // It should set the minimum USD fee.
        assertEq(merkleFactoryBase.minFeeUSD(), newMinFeeUSD, "min fee USD");
    }
}
