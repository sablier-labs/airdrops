// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable event-name-camelcase
pragma solidity >=0.8.22;

import { Assertions as LockupAssertions } from "@sablier/lockup/tests/utils/Assertions.sol";

import { ISablierMerkleFactoryBase } from "../../src/interfaces/ISablierMerkleFactoryBase.sol";
import { MerkleLT } from "../../src/types/DataTypes.sol";

abstract contract Assertions is LockupAssertions {
    event log_named_array(string key, MerkleLT.TrancheWithPercentage[] tranchesWithPercentages);

    /// @dev Compares two {ISablierMerkleFactoryBase} contracts.
    function assertEq(ISablierMerkleFactoryBase a, ISablierMerkleFactoryBase b) internal pure {
        assertEq(address(a), address(b), "factory contract");
    }

    /// @dev Compares two {MerkleLT.TrancheWithPercentage} arrays.
    function assertEq(MerkleLT.TrancheWithPercentage[] memory a, MerkleLT.TrancheWithPercentage[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log("Error: a == b not satisfied [MerkleLT.TrancheWithPercentage[]]");
            emit log_named_array("   Left", a);
            emit log_named_array("  Right", b);
            fail();
        }
    }
}
