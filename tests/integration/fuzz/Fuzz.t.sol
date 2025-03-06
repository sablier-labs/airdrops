// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { Integration_Test } from "../Integration.t.sol";

contract Shared_Fuzz_Test is Integration_Test {
    /// @dev Modifier to run tests across all the Merkle factories.
    modifier testAcrossAllFactories() {
        merkleFactoryBase = ISablierMerkleFactoryBase(merkleFactoryInstant);
        _;
        merkleFactoryBase = ISablierMerkleFactoryBase(merkleFactoryLL);
        _;
        merkleFactoryBase = ISablierMerkleFactoryBase(merkleFactoryLT);
        _;
        merkleFactoryBase = ISablierMerkleFactoryBase(merkleFactoryVCA);
        _;
    }
}
