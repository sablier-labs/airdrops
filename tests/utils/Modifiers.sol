// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { BaseTest as EvmUtilsBase } from "@sablier/evm-utils/src/tests/BaseTest.sol";
import { Users } from "./Types.sol";

abstract contract Modifiers is EvmUtilsBase {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users private users;

    function setVariables(Users memory _users) public {
        users = _users;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       GIVEN
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenCampaignNotExists() {
        _;
    }

    modifier givenCampaignNotExpired() {
        _;
    }

    modifier givenMsgValueNotLessThanFee() {
        _;
    }

    modifier givenRecipientNotClaimed() {
        _;
    }

    modifier givenSevenDaysPassed() {
        vm.warp({ newTimestamp: getBlockTimestamp() + 8 days });
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        WHEN
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenAmountValid() {
        _;
    }

    modifier whenCallerAdmin() {
        // Make the Admin the caller in the rest of this test suite.
        resetPrank({ msgSender: users.admin });
        _;
    }

    modifier whenCallerCampaignOwner() {
        resetPrank({ msgSender: users.campaignOwner });
        _;
    }

    modifier whenEndTimeGreaterThanStartTime() {
        _;
    }

    modifier whenExpirationNotZero() {
        _;
    }

    modifier whenExpiryNotExceedOneWeekFromEndTime() {
        _;
    }

    modifier whenFactoryAdminIsContract() {
        _;
    }

    modifier whenIndexInMerkleTree() {
        _;
    }

    modifier whenIndexValid() {
        _;
    }

    modifier whenMerkleProofValid() {
        _;
    }

    modifier whenNotZeroExpiry() {
        _;
    }

    modifier whenPercentagesSumNot100Pct() {
        _;
    }

    modifier whenProvidedMerkleLockupValid() {
        _;
    }

    modifier whenRecipientValid() {
        _;
    }

    modifier whenScheduledStartTimeZero() {
        _;
    }

    modifier whenStartTimeNotInFuture() {
        _;
    }

    modifier whenStartTimeNotZero() {
        _;
    }

    modifier whenTotalPercentage100() {
        _;
    }

    modifier whenTotalPercentageNot100() {
        _;
    }

    modifier whenTotalPercentageNotGreaterThan100() {
        _;
    }

    modifier whenWithdrawalAddressNotZero() {
        _;
    }
}
