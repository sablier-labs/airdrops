// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { Adminable } from "@sablier/evm-utils/src/Adminable.sol";

import { ISablierMerkleBase } from "../interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactoryBase } from "../interfaces/ISablierMerkleFactoryBase.sol";
import { Errors } from "../libraries/Errors.sol";
import { MerkleFactory } from "../types/DataTypes.sol";

/// @title SablierMerkleFactoryBase
/// @notice See the documentation in {ISablierMerkleFactoryBase}.
abstract contract SablierMerkleFactoryBase is
    ISablierMerkleFactoryBase, // 1 inherited component
    Adminable // 1 inherited component
{
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleFactoryBase
    uint256 public constant override MAX_MINIMUM_FEE = 100e8;

    /// @inheritdoc ISablierMerkleFactoryBase
    address public override chainlinkPriceFeed;

    /// @inheritdoc ISablierMerkleFactoryBase
    uint256 public override minimumFee;

    /// @dev A mapping of custom fees mapped by campaign creator addresses.
    mapping(address campaignCreator => MerkleFactory.CustomFee customFee) private _customFees;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Emits a {SetChainlinkPriceFeed} event.
    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialChainlinkPriceFeed The initial Chainlink price feed contract address.
    /// @param initialMinimumFee The initial minimum fee charged for claiming an airdrop.
    constructor(
        address initialAdmin,
        address initialChainlinkPriceFeed,
        uint256 initialMinimumFee
    )
        Adminable(initialAdmin)
    {
        minimumFee = initialMinimumFee;
        _setChainlinkPriceFeed(initialChainlinkPriceFeed, initialAdmin);
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleFactoryBase
    function getCustomFee(address campaignCreator) external view override returns (MerkleFactory.CustomFee memory) {
        return _customFees[campaignCreator];
    }

    /// @inheritdoc ISablierMerkleFactoryBase
    function getFee(address campaignCreator) external view returns (uint256) {
        return _getFee(campaignCreator);
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleFactoryBase
    function collectFees(ISablierMerkleBase merkleBase) external override {
        // Effect: collect the fees from the MerkleBase contract.
        uint256 feeAmount = merkleBase.collectFees(admin);

        // Log the fee withdrawal.
        emit CollectFees({ admin: admin, merkleBase: merkleBase, feeAmount: feeAmount });
    }

    /// @inheritdoc ISablierMerkleFactoryBase
    function resetCustomFee(address campaignCreator) external override onlyAdmin {
        delete _customFees[campaignCreator];

        // Log the reset.
        emit ResetCustomFee({ admin: msg.sender, campaignCreator: campaignCreator });
    }

    /// @inheritdoc ISablierMerkleFactoryBase
    function setChainlinkPriceFeed(address newChainlinkPriceFeed) external override onlyAdmin {
        _setChainlinkPriceFeed(newChainlinkPriceFeed, msg.sender);
    }

    /// @inheritdoc ISablierMerkleFactoryBase
    function setCustomFee(address campaignCreator, uint256 newFee) external override onlyAdmin {
        MerkleFactory.CustomFee storage customFeeByUser = _customFees[campaignCreator];

        // Check: if the user is not in the custom fee list.
        if (!customFeeByUser.enabled) {
            customFeeByUser.enabled = true;
        }

        // Check: the new fee is not greater than the maximum.
        if (newFee > MAX_MINIMUM_FEE) {
            revert Errors.SablierMerkleFactoryBase_MaximumFeeExceeded(newFee, MAX_MINIMUM_FEE);
        }

        // Effect: update the custom fee for the given campaign creator.
        customFeeByUser.fee = newFee;

        // Log the update.
        emit SetCustomFee({ admin: msg.sender, campaignCreator: campaignCreator, customFee: newFee });
    }

    /// @inheritdoc ISablierMerkleFactoryBase
    function setMinimumFee(uint256 newMinimumFee) external override onlyAdmin {
        // Check: the new minimum fee is not greater than the maximum.
        if (newMinimumFee > MAX_MINIMUM_FEE) {
            revert Errors.SablierMerkleFactoryBase_MaximumFeeExceeded(newMinimumFee, MAX_MINIMUM_FEE);
        }

        // Effect: update the minimum fee.
        minimumFee = newMinimumFee;

        // Log the update.
        emit SetMinimumFee({ admin: msg.sender, minimumFee: newMinimumFee });
    }

    /*//////////////////////////////////////////////////////////////////////////
                          PRIVATE NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _setChainlinkPriceFeed(address newChainlinkPriceFeed, address admin) private {
        // If the Chainlink address is not zero, verify that the price feed is valid.
        if (newChainlinkPriceFeed != address(0)) {
            (, int256 price,,,) = AggregatorV3Interface(newChainlinkPriceFeed).latestRoundData();

            // Check: the price is not zero.
            if (price == 0) {
                revert Errors.SablierMerkleFactoryBase_IncorrectChainlinkPriceFeed(newChainlinkPriceFeed);
            }
        }

        // Effect: update the Chainlink price feed.
        chainlinkPriceFeed = newChainlinkPriceFeed;

        // Log the update.
        emit SetChainlinkPriceFeed({ admin: admin, chainlinkPriceFeed: newChainlinkPriceFeed });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the fee for the provided campaign creator, using the minimum fee if no custom fee is set.
    function _getFee(address campaignCreator) internal view returns (uint256) {
        return _customFees[campaignCreator].enabled ? _customFees[campaignCreator].fee : minimumFee;
    }
}
