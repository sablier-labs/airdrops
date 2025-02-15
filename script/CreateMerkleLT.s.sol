// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";

import { ISablierMerkleFactory } from "../src/interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleLT } from "../src/interfaces/ISablierMerkleLT.sol";
import { MerkleBase, MerkleLT } from "../src/types/DataTypes.sol";

import { BaseScript } from "./Base.s.sol";

/// @dev Creates a dummy campaign to airdrop tokens through Lockup Tranched.
contract CreateMerkleLT is BaseScript {
    /// @dev Deploy via Forge.
    function run() public broadcast returns (ISablierMerkleLT merkleLT) {
        ISablierMerkleFactory merkleFactory = ISablierMerkleFactory(0x71DD3Ca88E7564416E5C2E350090C12Bf8F6144a);

        // Prepare the constructor parameters.
        MerkleBase.ConstructorParams memory baseParams;

        // The token to distribute through the campaign.
        baseParams.token = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

        // The campaign will expire in 30 days.
        baseParams.expiration = uint40(block.timestamp + 30 days);

        // The admin of the campaign.
        baseParams.initialAdmin = 0x79Fb3e81aAc012c08501f41296CCC145a1E15844;

        // Dummy values for the campaign name, IPFS CID, and the Merkle root hash.
        baseParams.campaignName = "The Boys LT";
        baseParams.ipfsCID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
        baseParams.merkleRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;

        // The tranches with their unlock percentages and durations.
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = new MerkleLT.TrancheWithPercentage[](2);
        tranchesWithPercentages[0] =
            MerkleLT.TrancheWithPercentage({ unlockPercentage: ud2x18(0.5e18), duration: 3600 });
        tranchesWithPercentages[1] =
            MerkleLT.TrancheWithPercentage({ unlockPercentage: ud2x18(0.5e18), duration: 7200 });

        // Deploy the MerkleLT contract.
        merkleLT = merkleFactory.createMerkleLT({
            baseParams: baseParams,
            lockup: ISablierLockup(0x7C01AA3783577E15fD7e272443D44B92d5b21056),
            cancelable: true,
            transferable: true,
            streamStartTime: 0, // i.e. block.timestamp
            tranchesWithPercentages: tranchesWithPercentages,
            aggregateAmount: 10_000e18,
            recipientCount: 100
        });
    }
}
