// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactory } from "src/interfaces/ISablierMerkleFactory.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleFactory } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract SetSablierFeeByUser_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactory.setSablierFeeByUser({ campaignCreator: users.campaignOwner, fee: 0 });
    }

    function test_WhenNotEnabled() external whenCallerAdmin {
        // It should emit a {SetSablierFee} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.SetSablierFeeForUser({
            admin: users.admin,
            campaignCreator: users.campaignOwner,
            sablierFee: 0
        });

        // Set the Sablier fee.
        merkleFactory.setSablierFeeByUser({ campaignCreator: users.campaignOwner, fee: 0 });

        MerkleFactory.SablierFeeByUser memory sablierFee = merkleFactory.sablierFeeByUser(users.campaignOwner);

        // It should enable the Sablier fee.
        assertTrue(sablierFee.enabled, "enabled");

        // It should set the Sablier fee.
        assertEq(sablierFee.fee, 0, "fee");
    }

    function test_WhenEnabled() external whenCallerAdmin {
        // Enable the Sablier fee.
        merkleFactory.setSablierFeeByUser({ campaignCreator: users.campaignOwner, fee: 0.001 ether });
        // Check that its enabled.
        MerkleFactory.SablierFeeByUser memory sablierFee = merkleFactory.sablierFeeByUser(users.campaignOwner);
        assertTrue(sablierFee.enabled, "enabled");
        assertEq(sablierFee.fee, 0.001 ether, "fee");

        // It should emit a {SetSablierFee} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.SetSablierFeeForUser({
            admin: users.admin,
            campaignCreator: users.campaignOwner,
            sablierFee: 1 ether
        });

        // Now set it to another fee.
        merkleFactory.setSablierFeeByUser({ campaignCreator: users.campaignOwner, fee: 1 ether });

        sablierFee = merkleFactory.sablierFeeByUser(users.campaignOwner);

        // It should enable the Sablier fee.
        assertTrue(sablierFee.enabled, "enabled");

        // It should set the Sablier fee.
        assertEq(sablierFee.fee, 1 ether, "fee");
    }
}
