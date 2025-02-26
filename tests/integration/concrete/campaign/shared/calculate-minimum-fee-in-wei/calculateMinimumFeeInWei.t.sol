// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract CalculateMinimumFeeInWei_Integration_Test is Integration_Test {
    string private _campaignType;

    constructor(string memory campaignType) {
        _campaignType = campaignType;
    }

    function test_GivenOracleAddressZero() external {
        resetPrank(users.admin);
        merkleFactoryBase.setOracle(address(0));

        if (Strings.equal(_campaignType, "instant")) {
            merkleInstant = createMerkleInstant();
            assertEq(merkleInstant.calculateMinimumFeeInWei(), 0, "minimum fee in wei");
        } else if (Strings.equal(_campaignType, "ll")) {
            merkleLL = createMerkleLL();
            assertEq(merkleLL.calculateMinimumFeeInWei(), 0, "minimum fee in wei");
        } else if (Strings.equal(_campaignType, "lt")) {
            merkleLT = createMerkleLT();
            assertEq(merkleLT.calculateMinimumFeeInWei(), 0, "minimum fee in wei");
        } else if (Strings.equal(_campaignType, "vca")) {
            merkleVCA = createMerkleVCA();
            assertEq(merkleVCA.calculateMinimumFeeInWei(), 0, "minimum fee in wei");
        }
    }

    function test_GivenMinimumFeeZero() external givenPriceFeedAddressNotZero {
        resetPrank(users.admin);
        merkleBase.setMinimumFeeToZero();
        assertEq(merkleBase.calculateMinimumFeeInWei(), 0, "minimum fee in wei");
    }

    function test_GivenMinimumFeeNotZero() external view givenPriceFeedAddressNotZero {
        assertEq(merkleBase.calculateMinimumFeeInWei(), MINIMUM_FEE_IN_WEI, "minimum fee in wei");
    }
}
