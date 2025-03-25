// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD2x18 } from "@prb/math/src/UD2x18.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";

library FactoryMerkle {
    /// @notice Struct encapsulating the parameters of a custom USD fee.
    /// @param enabled Whether the fee is enabled. If false, the min USD fee will apply instead.
    /// @param fee The fee amount.
    struct CustomFeeUSD {
        bool enabled;
        uint256 fee;
    }
}

library MerkleInstant {
    /// @notice Struct encapsulating the constructor parameters of Merkle Instant campaigns.
    /// @dev The fields are arranged alphabetically.
    /// @param campaignName The name of the campaign.
    /// @param expiration The expiration of the campaign, as a Unix timestamp. A value of zero means the campaign does
    /// not expire.
    /// @param initialAdmin The initial admin of the campaign.
    /// @param ipfsCID The content identifier for indexing the contract on IPFS.
    /// @param merkleRoot The Merkle root of the claim data.
    /// @param token The contract address of the ERC-20 token to be distributed.
    struct ConstructorParams {
        string campaignName;
        uint40 expiration;
        address initialAdmin;
        string ipfsCID;
        bytes32 merkleRoot;
        IERC20 token;
    }
}

library MerkleLL {
    /// @notice Struct encapsulating the constructor parameters of Merkle Lockup Linear campaigns.
    /// @dev The fields are arranged alphabetically.
    /// @param campaignName The name of the campaign.
    /// @param cancelable Indicates if the Lockup stream will be cancelable after claiming.
    /// @param cliffDuration The cliff duration of the vesting stream, in seconds.
    /// @param cliffUnlockPercentage The percentage of the claim amount due to be unlocked at the vesting cliff time, as
    /// a fixed-point number where 1e18 is 100%
    /// @param expiration The expiration of the campaign, as a Unix timestamp. A value of zero means the campaign does
    /// not expire.
    /// @param initialAdmin The initial admin of the campaign.
    /// @param ipfsCID The content identifier for indexing the contract on IPFS.
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param merkleRoot The Merkle root of the claim data.
    /// @param shape The shape of the vesting stream, used for differentiating between streams in the UI.
    /// @param startTime The start time of the vesting stream, as a Unix timestamp. Zero is a sentinel value for
    /// `block.timestamp`.
    /// @param startUnlockPercentage The percentage of the claim amount due to be unlocked at the vesting start time, as
    /// a fixed-point number where 1e18 is 100%.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param totalDuration The total duration of the vesting stream, in seconds.
    /// @param transferable Indicates if the Lockup stream will be transferable after claiming.
    struct ConstructorParams {
        string campaignName;
        bool cancelable;
        uint40 cliffDuration;
        UD60x18 cliffUnlockPercentage;
        uint40 expiration;
        address initialAdmin;
        string ipfsCID;
        ISablierLockup lockup;
        bytes32 merkleRoot;
        string shape;
        uint40 startTime;
        UD60x18 startUnlockPercentage;
        IERC20 token;
        uint40 totalDuration;
        bool transferable;
    }
}

library MerkleLT {
    /// @notice Struct encapsulating the constructor parameters of Merkle Lockup Tranched campaigns.
    /// @dev The fields are arranged alphabetically.
    /// @param campaignName The name of the campaign.
    /// @param cancelable Indicates if the Lockup stream will be cancelable after claiming.
    /// @param expiration The expiration of the campaign, as a Unix timestamp. A value of zero means the campaign does
    /// not expire.
    /// @param initialAdmin The initial admin of the campaign.
    /// @param ipfsCID The content identifier for indexing the contract on IPFS.
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param merkleRoot The Merkle root of the claim data.
    /// @param shape The shape of Lockup stream, used for differentiating between streams in the  UI.
    /// @param streamStartTime The start time of the vesting streams, as a Unix timestamp.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param tranchesWithPercentages The tranches with their respective unlock percentages, which are documented in
    /// {MerkleLT.TrancheWithPercentage}.
    /// @param transferable Indicates if the Lockup stream will be transferable after claiming.
    struct ConstructorParams {
        string campaignName;
        bool cancelable;
        uint40 expiration;
        address initialAdmin;
        string ipfsCID;
        ISablierLockup lockup;
        bytes32 merkleRoot;
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

library MerkleVCA {
    /// @notice Struct encapsulating the constructor parameters of Merkle VCA campaigns.
    /// @dev The fields are arranged alphabetically.
    /// @param campaignName The name of the campaign.
    /// @param endTime Vesting end time, as a Unix timestamp.
    /// @param expiration The expiration of the campaign, as a Unix timestamp.
    /// @param initialAdmin The initial admin of the campaign.
    /// @param ipfsCID The content identifier for indexing the contract on IPFS.
    /// @param merkleRoot The Merkle root of the claim data.
    /// @param startTime Vesting start time, as a Unix timestamp. Zero is a sentinel value for `block.timestamp`.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param unlockPercentage The percentage of the tokens allocated to a user to be unlocked at the start time,
    /// denoted as fixed-point number where 1e18 is 100%.
    struct ConstructorParams {
        string campaignName;
        uint40 endTime;
        uint40 expiration;
        address initialAdmin;
        string ipfsCID;
        bytes32 merkleRoot;
        uint40 startTime;
        IERC20 token;
        UD60x18 unlockPercentage;
    }
}
