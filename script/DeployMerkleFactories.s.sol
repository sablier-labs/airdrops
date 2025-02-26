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
        address initialOracle = getPriceFeedAddress();
        uint256 initialMinimumFee = getMinimumFee();
        merkleFactoryInstant = new SablierMerkleFactoryInstant(initialAdmin, initialMinimumFee, initialOracle);
        merkleFactoryLL = new SablierMerkleFactoryLL(initialAdmin, initialMinimumFee, initialOracle);
        merkleFactoryLT = new SablierMerkleFactoryLT(initialAdmin, initialMinimumFee, initialOracle);
        merkleFactoryVCA = new SablierMerkleFactoryVCA(initialAdmin, initialMinimumFee, initialOracle);
    }
}
