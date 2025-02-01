// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { uUNIT } from "@prb/math/src/UD2x18.sol";

import { Adminable } from "@sablier/lockup/src/abstracts/Adminable.sol";

import { ISablierMerkleBase } from "./interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactory } from "./interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleInstant } from "./interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "./interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "./interfaces/ISablierMerkleLT.sol";
import { SablierMerkleInstant } from "./SablierMerkleInstant.sol";
import { SablierMerkleLL } from "./SablierMerkleLL.sol";
import { SablierMerkleLT } from "./SablierMerkleLT.sol";
import { MerkleFactory, MerkleInstant, MerkleLL, MerkleLockup, MerkleLT } from "./types/DataTypes.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝

███╗   ███╗███████╗██████╗ ██╗  ██╗██╗     ███████╗    ███████╗ █████╗  ██████╗████████╗ ██████╗ ██████╗ ██╗   ██╗
████╗ ████║██╔════╝██╔══██╗██║ ██╔╝██║     ██╔════╝    ██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗╚██╗ ██╔╝
██╔████╔██║█████╗  ██████╔╝█████╔╝ ██║     █████╗      █████╗  ███████║██║        ██║   ██║   ██║██████╔╝ ╚████╔╝
██║╚██╔╝██║██╔══╝  ██╔══██╗██╔═██╗ ██║     ██╔══╝      ██╔══╝  ██╔══██║██║        ██║   ██║   ██║██╔══██╗  ╚██╔╝
██║ ╚═╝ ██║███████╗██║  ██║██║  ██╗███████╗███████╗    ██║     ██║  ██║╚██████╗   ██║   ╚██████╔╝██║  ██║   ██║
╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝

*/

/// @title SablierMerkleFactory
/// @notice See the documentation in {ISablierMerkleFactory}.
contract SablierMerkleFactory is
    ISablierMerkleFactory, // 1 inherited components
    Adminable // 1 inherited component
{
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleFactory
    uint256 public override defaultFee;

    /// @dev A mapping of custom fees mapped by campaign creator addresses.
    mapping(address campaignCreator => MerkleFactory.CustomFee customFee) private _customFees;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    constructor(address initialAdmin) Adminable(initialAdmin) { }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleFactory
    function getCustomFee(address campaignCreator) external view override returns (MerkleFactory.CustomFee memory) {
        return _customFees[campaignCreator];
    }

    /// @inheritdoc ISablierMerkleFactory
    function getFee(address campaignCreator) external view returns (uint256) {
        return _getFee(campaignCreator);
    }

    /// @inheritdoc ISablierMerkleFactory
    function isPercentagesSum100(MerkleLT.TrancheWithPercentage[] calldata tranches)
        external
        pure
        override
        returns (bool result)
    {
        uint256 totalPercentage;
        for (uint256 i = 0; i < tranches.length; ++i) {
            totalPercentage += tranches[i].unlockPercentage.unwrap();
        }
        return totalPercentage == uUNIT;
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleFactory
    function collectFees(ISablierMerkleBase merkleBase) external override {
        // Effect: collect the fees from the MerkleBase contract.
        uint256 feeAmount = merkleBase.collectFees(admin);

        // Log the fee withdrawal.
        emit CollectFees({ admin: admin, merkleBase: merkleBase, feeAmount: feeAmount });
    }

    /// @inheritdoc ISablierMerkleFactory
    function createMerkleInstant(
        MerkleInstant.ConstructorParams memory baseParams,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        override
        returns (ISablierMerkleInstant merkleInstant)
    {
        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, abi.encode(baseParams)));

        // Deploy the MerkleInstant contract with CREATE2.
        merkleInstant = new SablierMerkleInstant{ salt: salt }({ baseParams: baseParams, campaignCreator: msg.sender });

        // Log the creation of the MerkleInstant contract, including some metadata that is not stored on-chain.
        emit CreateMerkleInstant({
            merkleInstant: merkleInstant,
            baseParams: baseParams,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount,
            fee: _getFee(msg.sender)
        });
    }

    /// @inheritdoc ISablierMerkleFactory
    function createMerkleLL(
        MerkleLockup.ConstructorParams memory baseParams,
        MerkleLL.Schedule memory schedule,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        override
        returns (ISablierMerkleLL merkleLL)
    {
        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, abi.encode(baseParams), abi.encode(schedule)));

        // Deploy the MerkleLL contract with CREATE2.
        merkleLL = new SablierMerkleLL{ salt: salt }({
            baseParams: baseParams,
            campaignCreator: msg.sender,
            schedule: schedule
        });

        // Log the creation of the MerkleLL contract, including some metadata that is not stored on-chain.
        emit CreateMerkleLL({
            merkleLL: merkleLL,
            baseParams: baseParams,
            schedule: schedule,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount,
            fee: _getFee(msg.sender)
        });
    }

    /// @inheritdoc ISablierMerkleFactory
    function createMerkleLT(
        MerkleLockup.ConstructorParams memory baseParams,
        uint40 streamStartTime,
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        override
        returns (ISablierMerkleLT merkleLT)
    {
        // Calculate the sum of percentages and durations across all tranches.
        uint256 count = tranchesWithPercentages.length;
        uint256 totalDuration;
        for (uint256 i = 0; i < count; ++i) {
            unchecked {
                // Safe to use `unchecked` because its only used in the event.
                totalDuration += tranchesWithPercentages[i].duration;
            }
        }

        // Deploy the MerkleLT contract.
        merkleLT = _deployMerkleLT({
            baseParams: baseParams,
            streamStartTime: streamStartTime,
            tranchesWithPercentages: tranchesWithPercentages
        });

        // Log the creation of the MerkleLT contract, including some metadata that is not stored on-chain.
        emit CreateMerkleLT({
            merkleLT: merkleLT,
            baseParams: baseParams,
            streamStartTime: streamStartTime,
            tranchesWithPercentages: tranchesWithPercentages,
            totalDuration: totalDuration,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount,
            fee: _getFee(msg.sender)
        });
    }

    /// @inheritdoc ISablierMerkleFactory
    function resetCustomFee(address campaignCreator) external override onlyAdmin {
        delete _customFees[campaignCreator];

        // Log the reset.
        emit ResetCustomFee({ admin: msg.sender, campaignCreator: campaignCreator });
    }

    /// @inheritdoc ISablierMerkleFactory
    function setCustomFee(address campaignCreator, uint256 newFee) external override onlyAdmin {
        MerkleFactory.CustomFee storage customFeeByUser = _customFees[campaignCreator];

        // Check: if the user is not in the custom fee list.
        if (!customFeeByUser.enabled) {
            customFeeByUser.enabled = true;
        }

        // Effect: update the custom fee for the given campaign creator.
        customFeeByUser.fee = newFee;

        // Log the update.
        emit SetCustomFee({ admin: msg.sender, campaignCreator: campaignCreator, customFee: newFee });
    }

    /// @inheritdoc ISablierMerkleFactory
    function setDefaultFee(uint256 defaultFee_) external override onlyAdmin {
        // Effect: update the default fee.
        defaultFee = defaultFee_;

        emit SetDefaultFee(msg.sender, defaultFee_);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PRIVATE CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the fee for the provided campaign creator, using the default fee if no custom fee is set.
    function _getFee(address campaignCreator) private view returns (uint256) {
        return _customFees[campaignCreator].enabled ? _customFees[campaignCreator].fee : defaultFee;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           PRIVATE NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Deploys a new MerkleLT contract with CREATE2.
    /// @dev We need a separate function to prevent the stack too deep error.
    function _deployMerkleLT(
        MerkleLockup.ConstructorParams memory baseParams,
        uint40 streamStartTime,
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages
    )
        private
        returns (ISablierMerkleLT merkleLT)
    {
        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(
            abi.encodePacked(msg.sender, abi.encode(baseParams), streamStartTime, abi.encode(tranchesWithPercentages))
        );

        // Deploy the MerkleLT contract with CREATE2.
        merkleLT = new SablierMerkleLT{ salt: salt }({
            baseParams: baseParams,
            campaignCreator: msg.sender,
            streamStartTime: streamStartTime,
            tranchesWithPercentages: tranchesWithPercentages
        });
    }
}
