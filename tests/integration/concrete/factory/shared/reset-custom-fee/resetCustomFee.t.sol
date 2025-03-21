// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract ResetCustomFee_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactoryBase.resetCustomFee({ campaignCreator: users.campaignCreator });
    }

    function test_WhenNotEnabled() external whenCallerAdmin {
        // Check that custom fee is not enabled for user.
        assertEq(merkleFactoryBase.getFee(users.campaignCreator), merkleFactoryBase.minFeeUSD(), "custom fee enabled");

        // It should emit a {ResetCustomFee} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.ResetCustomFee({ admin: users.admin, campaignCreator: users.campaignCreator });

        // Reset the custom fee.
        merkleFactoryBase.resetCustomFee({ campaignCreator: users.campaignCreator });

        // It should return the minimum fee in `getFee`.
        assertEq(merkleFactoryBase.getFee(users.campaignCreator), merkleFactoryBase.minFeeUSD(), "custom fee changed");
    }

    function test_WhenEnabled() external whenCallerAdmin {
        // Enable the custom fee.
        merkleFactoryBase.setCustomFee({ campaignCreator: users.campaignCreator, newFee: 0.5e8 });

        // Check that custom fee is enabled for user by checking that it is not equal to the minimum fee.
        assertNotEq(
            merkleFactoryBase.getFee(users.campaignCreator), merkleFactoryBase.minFeeUSD(), "custom fee not enabled"
        );

        // It should emit a {ResetCustomFee} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.ResetCustomFee({ admin: users.admin, campaignCreator: users.campaignCreator });

        // Reset the custom fee.
        merkleFactoryBase.resetCustomFee({ campaignCreator: users.campaignCreator });

        // It should return the minimum fee in `getFee`.
        assertEq(
            merkleFactoryBase.getFee(users.campaignCreator), merkleFactoryBase.minFeeUSD(), "custom fee not changed"
        );
    }
}
