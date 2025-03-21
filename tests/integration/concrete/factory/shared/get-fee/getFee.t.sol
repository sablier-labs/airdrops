// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract GetFee_Integration_Test is Integration_Test {
    function test_GivenCustomFeeNotSet() external view {
        // It should return minimum fee.
        assertEq(merkleFactoryBase.getFee(users.campaignCreator), MIN_FEE_USD, "minimum fee");
    }

    function test_GivenCustomFeeSet() external {
        // Set a custom fee.
        resetPrank({ msgSender: users.admin });
        merkleFactoryBase.setCustomFeeUSD({ campaignCreator: users.campaignCreator, customFeeUSD: 0 });

        // It should return the custom fee.
        assertEq(merkleFactoryBase.getFee(users.campaignCreator), 0, "custom fee");
    }
}
