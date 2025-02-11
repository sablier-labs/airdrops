// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierMerkleFactory } from "src/interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { MerkleInstant } from "src/types/DataTypes.sol";

import { BaseScript } from "./Base.s.sol";

/// @dev Creates a dummy campaign to airdrop tokens instantly.
contract CreateMerkleInstant is BaseScript {
    /// @dev Deploy via Forge.
    function run() public broadcast returns (ISablierMerkleInstant merkleInstant) {
        ISablierMerkleFactory merkleFactory = ISablierMerkleFactory(0x71DD3Ca88E7564416E5C2E350090C12Bf8F6144a);

        // Prepare the constructor parameters.
        MerkleInstant.CreateParams memory createParams;
        createParams.campaignName = "The Boys Instant";
        createParams.expiration = uint40(block.timestamp + 30 days);
        createParams.initialAdmin = 0x79Fb3e81aAc012c08501f41296CCC145a1E15844;
        createParams.ipfsCID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
        createParams.merkleRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;
        createParams.token = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

        // The total amount to airdrop through the campaign.
        createParams.aggregateAmount = 10_000e18;

        // The number of eligible users for the airdrop.
        createParams.recipientCount = 100;

        // Deploy the MerkleInstant contract.
        merkleInstant = merkleFactory.createMerkleInstant(createParams);
    }
}
