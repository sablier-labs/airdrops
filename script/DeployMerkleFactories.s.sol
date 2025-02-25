// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { SablierMerkleFactoryInstant } from "../src/SablierMerkleFactoryInstant.sol";
import { SablierMerkleFactoryLL } from "../src/SablierMerkleFactoryLL.sol";
import { SablierMerkleFactoryLT } from "../src/SablierMerkleFactoryLT.sol";
import { SablierMerkleFactoryVCA } from "../src/SablierMerkleFactoryVCA.sol";
import { ChainlinkPriceFeedAddresses } from "../src/tests/ChainlinkPriceFeedAddresses.sol";
import { InitialMinimumFee } from "../src/tests/InitialMinimumFee.sol";

/// @notice Deploys Merkle factory contracts.
contract DeployMerkleFactories is BaseScript, ChainlinkPriceFeedAddresses, InitialMinimumFee {
    /// @dev Deploy via Forge.
    function run()
        public
        broadcast
        returns (
            SablierMerkleFactoryInstant merkleFactoryInstant,
            SablierMerkleFactoryLL merkleFactoryLL,
            SablierMerkleFactoryLT merkleFactoryLT,
            SablierMerkleFactoryVCA merkleFactoryVCA
        )
    {
        address initialAdmin = protocolAdmin();
        address initialChainlinkPriceFeed = getPriceFeedAddress();
        uint256 initialMinimumFee = getMinimumFee();
        merkleFactoryInstant =
            new SablierMerkleFactoryInstant(initialAdmin, initialChainlinkPriceFeed, initialMinimumFee);
        merkleFactoryLL = new SablierMerkleFactoryLL(initialAdmin, initialChainlinkPriceFeed, initialMinimumFee);
        merkleFactoryLT = new SablierMerkleFactoryLT(initialAdmin, initialChainlinkPriceFeed, initialMinimumFee);
        merkleFactoryVCA = new SablierMerkleFactoryVCA(initialAdmin, initialChainlinkPriceFeed, initialMinimumFee);
    }
}
