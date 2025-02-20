// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { Adminable } from "@sablier/lockup/src/abstracts/Adminable.sol";

import { ISablierMerkleBase } from "../interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactoryBase } from "../interfaces/ISablierMerkleFactoryBase.sol";
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
    AggregatorV3Interface public override chainlinkPriceFeed;

    /// @dev A mapping of custom fees mapped by campaign creator addresses.
    mapping(address campaignCreator => MerkleFactory.CustomFee customFee) private _customFees;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialPriceFeed The initial Chainlink price feed contract.
    constructor(address initialAdmin, address initialPriceFeed) Adminable(initialAdmin) {
        chainlinkPriceFeed = AggregatorV3Interface(initialPriceFeed);
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleFactoryBase
    function calculateMinimumFee() public view returns (uint256) {
        // Chainlink returns the ETH price in USD with 8 decimals.
        (, int256 price,,,) = chainlinkPriceFeed.latestRoundData();

        // Q: should we return 0, or revert?
        require(price > 0, "Invalid price");

        // Convert the price to 18 decimals format.
        uint256 nativeTokenAmount = (1e18 * 10 ** 8) / uint256(price);

        return nativeTokenAmount;
    }

    /// @inheritdoc ISablierMerkleFactoryBase
    function getCustomFee(address campaignCreator) external view override returns (MerkleFactory.CustomFee memory) {
        return _customFees[campaignCreator];
    }

    /// @inheritdoc ISablierMerkleFactoryBase
    function getFeeFor(address campaignCreator) external view returns (uint256) {
        uint256 minimumFee = calculateMinimumFee();
        return _customFees[campaignCreator].enabled ? _customFees[campaignCreator].fee : minimumFee;
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
    function setChainlinkPriceFeed(AggregatorV3Interface newChainlinkPriceFeed) external override onlyAdmin {
        // Effect: update the Chainlink price feed.
        chainlinkPriceFeed = newChainlinkPriceFeed;

        // Log the update.
        emit SetChainlinkPriceFeed({ admin: msg.sender, chainlinkPriceFeed: newChainlinkPriceFeed });
    }

    /// @inheritdoc ISablierMerkleFactoryBase
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
}
