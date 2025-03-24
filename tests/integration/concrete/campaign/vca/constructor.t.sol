// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleVCA } from "src/SablierMerkleVCA.sol";

import { MerkleVCA_Integration_Shared_Test } from "./MerkleVCA.t.sol";

contract Constructor_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test {
    function test_Constructor() external {
        // Make Factory the caller for the constructor test.
        resetPrank(address(factoryMerkleVCA));

        // Deploy the SablierMerkleVCA contract.
        SablierMerkleVCA constructedVCA = new SablierMerkleVCA(merkleVCAConstructorParams(), users.campaignCreator);

        // SablierMerkleBase
        assertEq(constructedVCA.admin(), users.campaignCreator, "admin");
        assertEq(constructedVCA.campaignName(), CAMPAIGN_NAME, "campaign name");
        assertEq(constructedVCA.EXPIRATION(), EXPIRATION, "expiration");
        assertEq(constructedVCA.FACTORY(), address(factoryMerkleVCA), "factory");
        assertEq(constructedVCA.ipfsCID(), IPFS_CID, "IPFS CID");
        assertEq(constructedVCA.MERKLE_ROOT(), MERKLE_ROOT, "Merkle root");
        assertEq(constructedVCA.minFeeUSD(), MIN_FEE_USD, "min fee USD");
        assertEq(constructedVCA.ORACLE(), address(oracle), "oracle");
        assertEq(address(constructedVCA.TOKEN()), address(dai), "token");

        // SablierMerkleVCA
        assertEq(constructedVCA.getSchedule().endTime, RANGED_STREAM_END_TIME, "schedule end time");
        assertEq(constructedVCA.getSchedule().startTime, RANGED_STREAM_START_TIME, "schedule start time");
        assertEq(constructedVCA.totalForgoneAmount(), 0, "total forgone amount");
    }
}
