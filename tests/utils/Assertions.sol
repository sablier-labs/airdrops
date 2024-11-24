// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable event-name-camelcase
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PRBMathAssertions } from "@prb/math/test/utils/Assertions.sol";
import { Lockup, LockupTranched } from "@sablier/lockup/types/DataTypes.sol";

import { MerkleLT } from "../../src/types/DataTypes.sol";

abstract contract Assertions is PRBMathAssertions {
    event log_named_array(string key, LockupTranched.Tranche[] tranches);
    event log_named_array(string key, MerkleLT.TrancheWithPercentage[] tranchesWithPercentages);

    event log_named_uint8(string key, uint40 value);

    /// @dev Compares two {IERC20} values.
    function assertEq(IERC20 a, IERC20 b, string memory err) internal pure {
        assertEq(address(a), address(b), err);
    }

    /// @dev Compares two {Lockup.Model} enum values.
    function assertEq(Lockup.Model a, Lockup.Model b) internal {
        assertEqUint8(uint8(a), uint8(b));
    }

    /// @dev Compares two {LockupTranched.Tranche} arrays.
    function assertEq(LockupTranched.Tranche[] memory a, LockupTranched.Tranche[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log("Error: a == b not satisfied [LockupTranched.Tranche[]]");
            emit log_named_array("   Left", a);
            emit log_named_array("  Right", b);
            fail();
        }
    }

    /// @dev Compares two {LockupTranched.Tranche} arrays.
    function assertEq(
        LockupTranched.Tranche[] memory a,
        LockupTranched.Tranche[] memory b,
        string memory err
    )
        internal
    {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
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

    /// @dev Compares two {MerkleLT.TrancheWithPercentage} arrays.
    function assertEq(
        MerkleLT.TrancheWithPercentage[] memory a,
        MerkleLT.TrancheWithPercentage[] memory b,
        string memory err
    )
        internal
    {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    /// @dev Compares two `uint40` numbers.
    function assertEqUint8(uint8 a, uint8 b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [uint8]");
            emit log_named_uint8("   Left", a);
            emit log_named_uint8("  Right", b);
            fail();
        }
    }
}
