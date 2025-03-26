// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { uUNIT } from "@prb/math/src/UD2x18.sol";
import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";

abstract contract Constants {
    // Amounts
    uint256 public constant AGGREGATE_AMOUNT = CLAIM_AMOUNT * RECIPIENT_COUNT;
    uint128 public constant CLAIM_AMOUNT = 10_000e18;
    uint128 public constant CLIFF_AMOUNT = (CLAIM_AMOUNT * VESTING_CLIFF_DURATION) / VESTING_TOTAL_DURATION;
    uint256 public constant MAX_FEE_USD = 100e8; // $100
    uint256 public constant MIN_FEE_USD = 3e8; // $3 fee
    uint256 public constant MIN_FEE_WEI = (1e18 * MIN_FEE_USD) / 3000e8; // at $3000 per ETH price
    uint128 public constant UNLOCK_START_AMOUNT = 100e18;
    UD60x18 public immutable VESTING_CLIFF_UNLOCK_PERCENTAGE = ud(CLIFF_AMOUNT).div(ud(CLAIM_AMOUNT));
    UD60x18 public immutable VESTING_START_UNLOCK_PERCENTAGE = ud(UNLOCK_START_AMOUNT).div(ud(CLAIM_AMOUNT));
    uint128 public constant VCA_FULL_AMOUNT = CLAIM_AMOUNT;

    // Durations and Timestamps
    uint40 public immutable EXPIRATION = FEB_1_2025 + 12 weeks;
    uint40 public constant FIRST_CLAIM_TIME = FEB_1_2025;
    uint40 public constant VESTING_CLIFF_DURATION = 2 days;
    uint40 public constant VESTING_END_TIME = VESTING_START_TIME + VESTING_TOTAL_DURATION;
    uint40 public constant VESTING_START_TIME = FEB_1_2025 - 2 days;
    uint40 public constant VESTING_TOTAL_DURATION = 10 days;

    // Global
    uint40 internal constant FEB_1_2025 = 1_738_368_000;
    uint64 public constant TOTAL_PERCENTAGE = uUNIT;

    // Merkle Campaigns
    string public CAMPAIGN_NAME = "Airdrop Campaign";
    uint256 public constant INDEX1 = 1;
    uint256 public constant INDEX2 = 2;
    uint256 public constant INDEX3 = 3;
    uint256 public constant INDEX4 = 4;
    string public constant IPFS_CID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
    uint256[] public LEAVES = new uint256[](RECIPIENT_COUNT);
    uint256 public constant RECIPIENT_COUNT = 4;
    bytes32 public MERKLE_ROOT;
    bool public constant STREAM_CANCELABLE = false;
    string public STREAM_SHAPE = "A custom stream shape";
    bool public constant STREAM_TRANSFERABLE = false;
}
