// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD2x18 } from "@prb/math/src/UD2x18.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";

library MerkleFactory {
    /// @notice Struct encapsulating the custom fee details for a given campaign creator.
    /// @param enabled Whether the fee is enabled. If false, the default fee will be applied for campaigns created by
    /// the given creator.
    /// @param fee The fee amount.
    struct CustomFee {
        bool enabled;
        uint256 fee;
    }
}

library MerkleInstant {
    /// @notice Struct encapsulating the constructor parameters of Merkle Instant campaigns.
    /// @param aggregateAmount The total amount of ERC-20 tokens to be distributed to all recipients.
    /// @param campaignName The name of the campaign.
    /// @param expiration The expiration of the campaign, as a Unix timestamp. A value of zero means the campaign does
    /// not expire.
    /// @param initialAdmin The initial admin of the campaign.
    /// @param ipfsCID The content identifier for indexing the contract on IPFS.
    /// @param merkleRoot The Merkle root of the claim data.
    /// @param recipientCount The total number of recipients who are eligible to claim.
    /// @param token The contract address of the ERC-20 token to be distributed.
    struct CreateParams {
        uint256 aggregateAmount;
        string campaignName;
        uint40 expiration;
        address initialAdmin;
        string ipfsCID;
        bytes32 merkleRoot;
        uint256 recipientCount;
        IERC20 token;
    }
}

library MerkleLL {
    /// @notice Struct encapsulating the constructor parameters of Merkle Lockup Linear campaigns.
    /// @param aggregateAmount The total amount of ERC-20 tokens to be distributed to all recipients.
    /// @param campaignName The name of the campaign.
    /// @param cancelable Indicates if the Lockup stream will be cancelable after claiming.
    /// @param expiration The expiration of the campaign, as a Unix timestamp. A value of zero means the campaign does
    /// not expire.
    /// @param initialAdmin The initial admin of the campaign.
    /// @param ipfsCID The content identifier for indexing the contract on IPFS.
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param merkleRoot The Merkle root of the claim data.
    /// @param recipientCount The total number of recipients who are eligible to claim.
    /// @param schedule Struct encapsulating the unlocks schedule, which are documented in {MerkleLL.Schedule}.
    /// @param shape The shape of Lockup stream, used for differentiating between streams in the  UI.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param transferable Indicates if the Lockup stream will be transferable after claiming.
    struct CreateParams {
        uint256 aggregateAmount;
        string campaignName;
        bool cancelable;
        uint40 expiration;
        address initialAdmin;
        string ipfsCID;
        ISablierLockup lockup;
        bytes32 merkleRoot;
        uint256 recipientCount;
        MerkleLL.Schedule schedule;
        string shape;
        IERC20 token;
        bool transferable;
    }

    /// @notice Struct encapsulating the start time, cliff duration and the end duration used to construct the time
    /// variables in `Lockup.CreateWithTimestampsLL`.
    /// @dev A start time value of zero will be considered as `block.timestamp`.
    /// @param startTime The start time of the stream.
    /// @param startPercentage The percentage to be unlocked at the start time.
    /// @param cliffDuration The duration of the cliff.
    /// @param cliffPercentage The percentage to be unlocked at the cliff time.
    /// @param totalDuration The total duration of the stream.
    struct Schedule {
        uint40 startTime;
        UD2x18 startPercentage;
        uint40 cliffDuration;
        UD2x18 cliffPercentage;
        uint40 totalDuration;
    }
}

library MerkleLT {
    /// @notice Struct encapsulating the constructor parameters of Merkle Lockup Tranched campaigns.
    /// @param aggregateAmount The total amount of ERC-20 tokens to be distributed to all recipients.
    /// @param campaignName The name of the campaign.
    /// @param cancelable Indicates if the Lockup stream will be cancelable after claiming.
    /// @param expiration The expiration of the campaign, as a Unix timestamp. A value of zero means the campaign does
    /// not expire.
    /// @param initialAdmin The initial admin of the campaign.
    /// @param ipfsCID The content identifier for indexing the contract on IPFS.
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param merkleRoot The Merkle root of the claim data.
    /// @param recipientCount The total number of recipients who are eligible to claim.
    /// @param shape The shape of Lockup stream, used for differentiating between streams in the  UI.
    /// @param streamStartTime The start time of the streams created through {SablierMerkleLT._claim}.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param tranchesWithPercentages The tranches with their respective unlock percentages, which are documented in
    /// {MerkleLT.TrancheWithPercentage}.
    /// @param transferable Indicates if the Lockup stream will be transferable after claiming.
    struct CreateParams {
        uint256 aggregateAmount;
        string campaignName;
        bool cancelable;
        uint40 expiration;
        address initialAdmin;
        string ipfsCID;
        ISablierLockup lockup;
        bytes32 merkleRoot;
        uint256 recipientCount;
        string shape;
        uint40 streamStartTime;
        IERC20 token;
        MerkleLT.TrancheWithPercentage[] tranchesWithPercentages;
        bool transferable;
    }

    /// @notice Struct encapsulating the unlock percentage and duration of a tranche.
    /// @dev Since users may have different amounts allocated, this struct makes it possible to calculate the amounts
    /// at claim time. An 18-decimal format is used to represent percentages: 100% = 1e18. For more information, see
    /// the PRBMath documentation on UD2x18: https://github.com/PaulRBerg/prb-math
    /// @param unlockPercentage The percentage designated to be unlocked in this tranche.
    /// @param duration The time difference in seconds between this tranche and the previous one.
    struct TrancheWithPercentage {
        // slot 0
        UD2x18 unlockPercentage;
        uint40 duration;
    }
}
