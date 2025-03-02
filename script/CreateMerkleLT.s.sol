// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";

import { ISablierMerkleLT } from "../src/interfaces/ISablierMerkleLT.sol";
import { SablierMerkleFactoryLT } from "../src/SablierMerkleFactoryLT.sol";

import { MerkleLT } from "../src/types/DataTypes.sol";
import { BaseScript } from "./Base.s.sol";

/// @dev Creates a dummy campaign to airdrop tokens through Lockup Tranched.
contract CreateMerkleLT is BaseScript {
    /// @dev Deploy via Forge.
    function run() public broadcast returns (ISablierMerkleLT merkleLT) {
        // TODO: Load deployed addresses from Ethereum mainnet.
        SablierMerkleFactoryLT merkleFactory = new SablierMerkleFactoryLT({
            initialAdmin: DEFAULT_SABLIER_ADMIN,
            initialMinimumFee: ONE_DOLLAR,
            initialOracle: chainlinkOracle()
        });

        // Prepare the constructor parameters.
        MerkleLT.ConstructorParams memory params;
        params.campaignName = "The Boys LT";
        params.cancelable = true;
        params.expiration = uint40(block.timestamp + 30 days);
        params.lockup = ISablierLockup(0x7C01AA3783577E15fD7e272443D44B92d5b21056);
        params.initialAdmin = 0x79Fb3e81aAc012c08501f41296CCC145a1E15844;
        params.ipfsCID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
        params.merkleRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;
        params.token = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        params.transferable = true;

        // The tranches with their unlock percentages and durations.
        params.tranchesWithPercentages = new MerkleLT.TrancheWithPercentage[](2);
        params.tranchesWithPercentages[0] =
            MerkleLT.TrancheWithPercentage({ unlockPercentage: ud2x18(0.5e18), duration: 3600 });
        params.tranchesWithPercentages[1] =
            MerkleLT.TrancheWithPercentage({ unlockPercentage: ud2x18(0.5e18), duration: 7200 });

        params.streamStartTime = 0; // i.e. block.timestamp
        uint256 aggregateAmount = 10_000e18;
        uint256 recipientCount = 100;

        // Deploy the MerkleLT contract.
        merkleLT = merkleFactory.createMerkleLT(params, aggregateAmount, recipientCount);
    }
}
