// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract DisableCustomFeeUSD_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactoryBase.disableCustomFeeUSD({ campaignCreator: users.campaignCreator });
    }

    function test_WhenNotEnabled() external whenCallerAdmin {
        // Check that custom fee is not enabled.
        assertEq(
            merkleFactoryBase.getFee(users.campaignCreator), merkleFactoryBase.minFeeUSD(), "custom fee USD enabled"
        );

        // It should emit a {DisableCustomFeeUSD} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.DisableCustomFeeUSD({ admin: users.admin, campaignCreator: users.campaignCreator });

        // Reset the custom fee.
        merkleFactoryBase.disableCustomFeeUSD({ campaignCreator: users.campaignCreator });

        // It should return the min fee.
        assertEq(
            merkleFactoryBase.getFee(users.campaignCreator), merkleFactoryBase.minFeeUSD(), "custom fee USD changed"
        );
    }

    function test_WhenEnabled() external whenCallerAdmin {
        // Enable the custom fee.
        merkleFactoryBase.setCustomFeeUSD({ campaignCreator: users.campaignCreator, customFeeUSD: 0.5e8 });

        // Check that custom fee is enabled.
        assertNotEq(
            merkleFactoryBase.getFee(users.campaignCreator), merkleFactoryBase.minFeeUSD(), "custom fee USD not enabled"
        );

        // It should emit a {DisableCustomFeeUSD} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.DisableCustomFeeUSD({ admin: users.admin, campaignCreator: users.campaignCreator });

        // Disable the custom fee.
        merkleFactoryBase.disableCustomFeeUSD({ campaignCreator: users.campaignCreator });

        // It should return the minimum USD fee.
        assertEq(
            merkleFactoryBase.getFee(users.campaignCreator), merkleFactoryBase.minFeeUSD(), "custom fee USD not changed"
        );
    }
}
