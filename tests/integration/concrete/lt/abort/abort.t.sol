// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleLT } from "src/types/DataTypes.sol";

import { Integration_Test } from "./../../../Integration.t.sol";

contract Abort_MerkleLT_Integration_Test is Integration_Test {
    address[] internal recipients;

    function setUp() public override {
        Integration_Test.setUp();

        recipients.push(users.recipient1);
        recipients.push(users.recipient2);
    }

    function test_RevertWhen_CallerNotCampaignOwner() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.campaignOwner, users.eve));
        merkleLTFixedStartTime.abort(recipients);
    }

    function test_RevertGiven_CampaignExpired() external whenCallerCampaignOwner {
        uint40 expiration = defaults.EXPIRATION();
        uint256 warpTime = expiration + 1 seconds;
        vm.warp({ newTimestamp: warpTime });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_CampaignExpired.selector, warpTime, expiration));
        merkleLTFixedStartTime.abort(recipients);
    }

    function test_RevertGiven_CampaignNotCancelable() external whenCallerCampaignOwner givenCampaignNotExpired {
        ISablierMerkleLT merkleLT = merkleFactory.createMerkleLT({
            baseParams: defaults.baseParams(),
            lockup: lockup,
            cancelable: false,
            transferable: defaults.TRANSFERABLE(),
            streamStartTime: defaults.STREAM_START_TIME_NON_ZERO(),
            tranchesWithPercentages: defaults.tranchesWithPercentages(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleLT_NotCancelableCampaign.selector));
        merkleLT.abort(recipients);
    }

    modifier givenCampaignCancelable() {
        _;
    }

    function test_RevertGiven_StartTimeNotFix()
        external
        whenCallerCampaignOwner
        givenCampaignNotExpired
        givenCampaignCancelable
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleLT_StreamStartTimeNotFix.selector));
        merkleLT.abort(recipients);
    }

    modifier givenStreamStartTimeFix() {
        _;
    }

    function test_WhenArrayEmpty()
        external
        whenCallerCampaignOwner
        givenCampaignNotExpired
        givenCampaignCancelable
        givenStreamStartTimeFix
    {
        address[] memory emptyArray;
        merkleLTFixedStartTime.abort(emptyArray);
    }

    function test_WhenArrayNotEmpty()
        external
        whenCallerCampaignOwner
        givenCampaignNotExpired
        givenCampaignCancelable
        givenStreamStartTimeFix
    {
        uint40 abortTime = defaults.STREAM_START_TIME_NON_ZERO() + 1 days;
        vm.warp({ newTimestamp: abortTime });

        // It should emit an {Abort} event
        vm.expectEmit({ emitter: address(merkleLTFixedStartTime) });
        emit ISablierMerkleLT.Abort(recipients);
        merkleLTFixedStartTime.abort(recipients);

        // It should set the abort timestamps
        assertEq(merkleLTFixedStartTime.abortTimes(recipients[0]), abortTime, "abort timestamp");
        assertEq(merkleLTFixedStartTime.abortTimes(recipients[1]), abortTime, "abort timestamp");
    }
}
