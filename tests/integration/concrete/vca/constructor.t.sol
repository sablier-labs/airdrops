// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleVCA } from "src/SablierMerkleVCA.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Constructor_MerkleVCA_Integration_Test is Integration_Test {
    function test_Constructor() external {
        // Make Factory the caller for the constructor test.
        resetPrank(address(merkleFactory));

        SablierMerkleVCA actualMerkleVCA = new SablierMerkleVCA(merkleVCAConstructorParams(), users.campaignOwner);

        assertEq(actualMerkleVCA.admin(), users.campaignOwner, "admin");
        assertEq(actualMerkleVCA.campaignName(), defaults.CAMPAIGN_NAME(), "campaign name");
        assertEq(actualMerkleVCA.EXPIRATION(), defaults.EXPIRATION(), "expiration");
        assertEq(actualMerkleVCA.FACTORY(), address(merkleFactory), "factory");
        assertEq(actualMerkleVCA.MINIMUM_FEE(), defaults.MINIMUM_FEE(), "minimum fee");
        assertEq(actualMerkleVCA.ipfsCID(), defaults.IPFS_CID(), "ipfsCID");
        assertEq(actualMerkleVCA.MERKLE_ROOT(), defaults.MERKLE_ROOT(), "merkleRoot");
        assertEq(actualMerkleVCA.forgoneAmount(), 0, "forgoneAmount");
        assertEq(actualMerkleVCA.vestingSchedule().start, defaults.RANGED_STREAM_START_TIME(), "vesting start");
        assertEq(actualMerkleVCA.vestingSchedule().end, defaults.RANGED_STREAM_END_TIME(), "vesting end");
        assertEq(address(actualMerkleVCA.TOKEN()), address(dai), "token");
    }
}
