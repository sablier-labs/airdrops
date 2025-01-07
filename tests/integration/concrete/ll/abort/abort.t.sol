// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Integration_Test } from "./../../../Integration.t.sol";

;

contract Abort_MerkleLL_Integration_Test is Integration_Test {
    address[] internal recipients;

    function setUp() public override {
        Integration_Test.setUp();
        recipients.push(users.recipient1);
        recipients.push(users.recipient2);
    }

    function test_RevertGiven_CampaignExpired() external {
        uint40 expiration = defaults.EXPIRATION();
        uint256 warpTime = expiration + 1 seconds;
        vm.warp({ newTimestamp: warpTime });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_CampaignExpired.selector, warpTime, expiration));
        merkleLL.abort(recipients);
    }

    function test_RevertGiven_CampaignNotCancelable() external givenCampaignNotExpired {
        ISablierMerkleLL merkleLL = merkleFactory.createMerkleLL({
            baseParams: defaults.baseParams(),
            lockup: lockup,
            cancelable: false,
            transferable: defaults.TRANSFERABLE(),
            schedule: defaults.schedule(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleLL_NotCancelableCampaign.selector));
        merkleLL.abort(recipients);
    }

    modifier givenCampaignCancelable() {
        _;
    }

    function test_WhenArrayEmpty() external givenCampaignNotExpired givenCampaignCancelable {
        address[] memory emptyArray;
        merkleLL.abort(emptyArray);
    }

    function test_WhenArrayNotEmpty() external givenCampaignNotExpired givenCampaignCancelable {
        uint40 abortTime = defaults.STREAM_START_TIME_NON_ZERO() + 1 days;
        vm.warp({ newTimestamp: abortTime });

        // It should emit an {Abort} event
        vm.expectEmit({ emitter: address(merkleLL) });
        emit ISablierMerkleLL.Abort(recipients);
        merkleLL.abort(recipients);

        // It should set the abort timestamps
        assertEq(merkleLL.abortTimes(recipients[0]), abortTime, "abort timestamp");
        assertEq(merkleLL.abortTimes(recipients[1]), abortTime, "abort timestamp");
    }
}
