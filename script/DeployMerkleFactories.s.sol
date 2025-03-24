// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierFactoryMerkleInstant } from "../src/SablierFactoryMerkleInstant.sol";
import { SablierFactoryMerkleLL } from "../src/SablierFactoryMerkleLL.sol";
import { SablierFactoryMerkleLT } from "../src/SablierFactoryMerkleLT.sol";
import { SablierFactoryMerkleVCA } from "../src/SablierFactoryMerkleVCA.sol";
import { BaseScript } from "./Base.sol";

/// @notice Deploys Merkle factory contracts.
contract DeployMerkleFactories is BaseScript {
    function run()
        public
        broadcast
        returns (
            SablierFactoryMerkleInstant merkleFactoryInstant,
            SablierFactoryMerkleLL merkleFactoryLL,
            SablierFactoryMerkleLT merkleFactoryLT,
            SablierFactoryMerkleVCA merkleFactoryVCA
        )
    {
        address initialAdmin = protocolAdmin();
        uint256 initialMinFeeUSD = initialMinFeeUSD();
        address initialOracle = chainlinkOracle();
        merkleFactoryInstant = new SablierFactoryMerkleInstant(initialAdmin, initialMinFeeUSD, initialOracle);
        merkleFactoryLL = new SablierFactoryMerkleLL(initialAdmin, initialMinFeeUSD, initialOracle);
        merkleFactoryLT = new SablierFactoryMerkleLT(initialAdmin, initialMinFeeUSD, initialOracle);
        merkleFactoryVCA = new SablierFactoryMerkleVCA(initialAdmin, initialMinFeeUSD, initialOracle);
    }
}
