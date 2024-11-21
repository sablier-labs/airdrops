// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactory } from "src/interfaces/ISablierMerkleFactory.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract WithdrawFees_Integration_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Set the `merkleBase` to the merkleLL contract to use it in the tests.
        merkleBase = ISablierMerkleBase(merkleLL);

        // Claim to collect some fees.
        resetPrank(users.recipient);
        claim();
    }

    function test_RevertWhen_ProvidedMerkleLockupNotValid() external {
        vm.expectRevert();
        merkleFactory.withdrawFees(ISablierMerkleBase(users.eve));
    }

    function test_WhenFactoryAdminIsNotContract() external whenProvidedMerkleLockupValid {
        _test_WithdrawFees(users.admin);
    }

    function test_RevertWhen_FactoryAdminDoesNotImplementReceiveFunction()
        external
        whenProvidedMerkleLockupValid
        whenFactoryAdminIsContract
    {
        // Transfer the admin to a contract that does not implement the receive function.
        resetPrank({ msgSender: users.admin });
        merkleFactory.transferAdmin(address(contractWithoutReceiveEth));

        // Make the contract the caller.
        resetPrank({ msgSender: address(contractWithoutReceiveEth) });

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_FeeTransferFail.selector,
                address(contractWithoutReceiveEth),
                address(merkleBase).balance
            )
        );
        merkleFactory.withdrawFees(merkleBase);
    }

    function test_WhenFactoryAdminImplementsReceiveFunction()
        external
        whenProvidedMerkleLockupValid
        whenFactoryAdminIsContract
    {
        // Transfer the admin to a contract that implements the receive function.
        resetPrank({ msgSender: users.admin });
        merkleFactory.transferAdmin(address(contractWithReceiveEth));

        _test_WithdrawFees(address(contractWithReceiveEth));
    }

    function _test_WithdrawFees(address admin) private {
        // Load the initial ETH balance of the admin.
        uint256 initialAdminBalance = admin.balance;

        // It should emit a {WithdrawFees} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.WithdrawFees({
            admin: admin,
            merkleBase: merkleBase,
            feeAmount: defaults.DEFAULT_FEE()
        });

        // Make Alice the caller.
        resetPrank({ msgSender: users.eve });

        merkleFactory.withdrawFees(merkleBase);

        // It should decrease merkle contract balance to zero.
        assertEq(address(merkleBase).balance, 0, "merkle lockup ETH balance");

        // It should transfer fee to the factory admin.
        assertEq(admin.balance, initialAdminBalance + defaults.DEFAULT_FEE(), "admin ETH balance");
    }
}
