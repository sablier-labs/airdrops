// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleFactoryInstant } from "../src/SablierMerkleFactoryInstant.sol";
import { SablierMerkleFactoryLL } from "../src/SablierMerkleFactoryLL.sol";
import { SablierMerkleFactoryLT } from "../src/SablierMerkleFactoryLT.sol";
import { SablierMerkleFactoryVCA } from "../src/SablierMerkleFactoryVCA.sol";
import { BaseScript } from "./Base.s.sol";

/// @notice Deploys Merkle factory contracts.
contract DeployMerkleFactories is BaseScript {
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
        address initialOracle = chainlinkOracle();
        merkleFactoryInstant = new SablierMerkleFactoryInstant(initialAdmin, ONE_DOLLAR, initialOracle);
        merkleFactoryLL = new SablierMerkleFactoryLL(initialAdmin, ONE_DOLLAR, initialOracle);
        merkleFactoryLT = new SablierMerkleFactoryLT(initialAdmin, ONE_DOLLAR, initialOracle);
        merkleFactoryVCA = new SablierMerkleFactoryVCA(initialAdmin, ONE_DOLLAR, initialOracle);
    }
}
