// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../../Integration.t.sol";

contract ComputeFee_Integration_Test is Integration_Test {
    function test_GivenCustomFeeNotSet() external view {
        // It should return default fee.
        assertEq(merkleFactory.computeFee(users.campaignOwner), defaults.FEE(), "default fee");
    }

    function test_GivenCustomFeeSet() external {
        // Set the custom fee.
        resetPrank({ msgSender: users.admin });
        merkleFactory.setCustomFee({ campaignCreator: users.campaignOwner, newFee: 0 });

        // It should return custom fee.
        assertEq(merkleFactory.computeFee(users.campaignOwner), 0, "custom fee");
    }
}
