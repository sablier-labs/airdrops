// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleVCA } from "src/SablierMerkleVCA.sol";

import { MerkleVCA_Integration_Shared_Test } from "./MerkleVCA.t.sol";

contract Constructor_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test {
    function test_Constructor() external {
        // Make Factory the caller for the constructor test.
        resetPrank(address(merkleFactoryVCA));

        // Deploy the SablierMerkleVCA contract.
        SablierMerkleVCA constructedVCA = new SablierMerkleVCA(merkleVCAConstructorParams(), users.campaignCreator);

        // SablierMerkleBase
        assertEq(constructedVCA.admin(), users.campaignCreator, "admin");
        assertEq(constructedVCA.campaignName(), CAMPAIGN_NAME, "campaign name");
        assertEq(constructedVCA.EXPIRATION(), EXPIRATION, "expiration");
        assertEq(constructedVCA.FACTORY(), address(merkleFactoryVCA), "factory");
        assertEq(constructedVCA.ipfsCID(), IPFS_CID, "ipfsCID");
        assertEq(constructedVCA.MERKLE_ROOT(), MERKLE_ROOT, "merkleRoot");
        assertEq(constructedVCA.minimumFee(), MINIMUM_FEE, "minimum fee");
        assertEq(constructedVCA.ORACLE(), address(oracle), "oracle");
        assertEq(address(constructedVCA.TOKEN()), address(dai), "token");

        // SablierMerkleVCA
        assertEq(constructedVCA.getSchedule().endTime, RANGED_STREAM_END_TIME, "schedule end time");
        assertEq(constructedVCA.getSchedule().startTime, RANGED_STREAM_START_TIME, "schedule start time");
        assertEq(constructedVCA.totalForgoneAmount(), 0, "total forgone amount");
    }
}
