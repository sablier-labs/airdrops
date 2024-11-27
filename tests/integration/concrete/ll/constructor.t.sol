// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleLL } from "src/SablierMerkleLL.sol";
import { MerkleLL } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Constructor_MerkleLL_Integration_Test is Integration_Test {
    /// @dev Needed to prevent "Stack too deep" error
    struct Vars {
        address actualAdmin;
        uint256 actualAllowance;
        bool actualCancelable;
        uint40 actualExpiration;
        address actualFactory;
        string actualIpfsCID;
        address actualLockup;
        bytes32 actualMerkleRoot;
        string actualCampaignName;
        uint256 actualFee;
        MerkleLL.Schedule actualSchedule;
        address actualToken;
        bool actualTransferable;
        address expectedAdmin;
        uint256 expectedAllowance;
        bool expectedCancelable;
        uint40 expectedExpiration;
        address expectedFactory;
        string expectedIpfsCID;
        address expectedLockup;
        bytes32 expectedMerkleRoot;
        string expectedCampaignName;
        uint256 expectedFee;
        MerkleLL.Schedule expectedSchedule;
        address expectedToken;
        bool expectedTransferable;
    }

    function test_Constructor() external {
        // Make Factory the caller for the constructor test.
        resetPrank(address(merkleFactory));

        SablierMerkleLL constructedLL = new SablierMerkleLL(
            defaults.baseParams(),
            lockup,
            defaults.CANCELABLE(),
            defaults.TRANSFERABLE(),
            defaults.schedule(),
            defaults.FEE()
        );

        Vars memory vars;

        vars.actualAdmin = constructedLL.admin();
        vars.expectedAdmin = users.campaignOwner;
        assertEq(vars.actualAdmin, vars.expectedAdmin, "admin");

        vars.actualAllowance = dai.allowance(address(constructedLL), address(lockup));
        vars.expectedAllowance = MAX_UINT256;
        assertEq(vars.actualAllowance, vars.expectedAllowance, "allowance");

        vars.actualCancelable = constructedLL.CANCELABLE();
        vars.expectedCancelable = defaults.CANCELABLE();
        assertEq(vars.actualCancelable, vars.expectedCancelable, "cancelable");

        vars.actualExpiration = constructedLL.EXPIRATION();
        vars.expectedExpiration = defaults.EXPIRATION();
        assertEq(vars.actualExpiration, vars.expectedExpiration, "expiration");

        vars.actualFactory = constructedLL.FACTORY();
        vars.expectedFactory = address(merkleFactory);
        assertEq(vars.actualFactory, vars.expectedFactory, "factory");

        vars.actualFee = constructedLL.FEE();
        vars.expectedFee = defaults.FEE();
        assertEq(vars.actualFee, vars.expectedFee, "fee");

        vars.actualIpfsCID = constructedLL.ipfsCID();
        vars.expectedIpfsCID = defaults.IPFS_CID();
        assertEq(vars.actualIpfsCID, vars.expectedIpfsCID, "ipfsCID");

        vars.actualLockup = address(constructedLL.LOCKUP());
        vars.expectedLockup = address(lockup);
        assertEq(vars.actualLockup, vars.expectedLockup, "lockup");

        vars.actualMerkleRoot = constructedLL.MERKLE_ROOT();
        vars.expectedMerkleRoot = defaults.MERKLE_ROOT();
        assertEq(vars.actualMerkleRoot, vars.expectedMerkleRoot, "merkleRoot");

        vars.actualCampaignName = constructedLL.campaignName();
        vars.expectedCampaignName = defaults.CAMPAIGN_NAME();
        assertEq(vars.actualCampaignName, vars.expectedCampaignName, "campaign name");

        (
            vars.actualSchedule.startTime,
            vars.actualSchedule.startAmount,
            vars.actualSchedule.cliffDuration,
            vars.actualSchedule.cliffAmount,
            vars.actualSchedule.totalDuration
        ) = constructedLL.schedule();
        vars.expectedSchedule = defaults.schedule();
        assertEq(vars.actualSchedule.startTime, vars.expectedSchedule.startTime, "schedule.startTime");
        assertEq(vars.actualSchedule.startAmount, vars.expectedSchedule.startAmount, "schedule.startAmount");
        assertEq(vars.actualSchedule.cliffDuration, vars.expectedSchedule.cliffDuration, "schedule.cliffDuration");
        assertEq(vars.actualSchedule.cliffAmount, vars.expectedSchedule.cliffAmount, "schedule.cliffAmount");
        assertEq(vars.actualSchedule.totalDuration, vars.expectedSchedule.totalDuration, "schedule.totalDuration");

        assertEq(constructedLL.shape(), defaults.SHAPE(), "shape");

        vars.actualToken = address(constructedLL.TOKEN());
        vars.expectedToken = address(dai);
        assertEq(vars.actualToken, vars.expectedToken, "token");

        vars.actualTransferable = constructedLL.TRANSFERABLE();
        vars.expectedTransferable = defaults.TRANSFERABLE();
        assertEq(vars.actualTransferable, vars.expectedTransferable, "transferable");
    }
}
