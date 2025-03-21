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
    uint256 public constant override MAX_FEE_USD = 100e8;

    /// @inheritdoc ISablierMerkleFactoryBase
    address public override oracle;

    /// @inheritdoc ISablierMerkleFactoryBase
    uint256 public override minFeeUSD;

    /// @inheritdoc ISablierMerkleFactoryBase
    address public override nativeToken;

    /// @dev A mapping of custom fees mapped by campaign creator addresses.
    mapping(address campaignCreator => MerkleFactory.CustomFeeUSD customFeeUSD) private _customFeesUSD;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialMinFeeUSD The initial minimum fee charged for claiming an airdrop.
    /// @param initialOracle The initial oracle contract address.
    constructor(address initialAdmin, uint256 initialMinFeeUSD, address initialOracle) Adminable(initialAdmin) {
        minFeeUSD = initialMinFeeUSD;

        if (initialOracle != address(0)) {
            _setOracle(initialOracle);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleFactoryBase
    function minFeeUSDFor(address campaignCreator) external view returns (uint256) {
        return _minFeeUSDFor(campaignCreator);
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
    function disableCustomFeeUSD(address campaignCreator) external override onlyAdmin {
        delete _customFeesUSD[campaignCreator];

        // Log the reset.
        emit DisableCustomFeeUSD({ admin: msg.sender, campaignCreator: campaignCreator });
    }

    /// @inheritdoc ISablierMerkleFactoryBase
    function setCustomFeeUSD(address campaignCreator, uint256 customFeeUSD) external override onlyAdmin {
        MerkleFactory.CustomFeeUSD storage customFee = _customFeesUSD[campaignCreator];

        // Check: the new fee is not greater than the maximum
        if (customFeeUSD > MAX_FEE_USD) {
            revert Errors.SablierMerkleFactoryBase_MaxFeeUSDExceeded(customFeeUSD, MAX_FEE_USD);
        }

        // Effect: enable the custom fee for the user if it is not already enabled.
        if (!customFee.enabled) {
            customFee.enabled = true;
        }

        // Effect: update the custom fee for the provided campaign creator.
        customFee.fee = customFeeUSD;

        // Log the update.
        emit SetCustomFeeUSD({ admin: msg.sender, campaignCreator: campaignCreator, customFeeUSD: customFeeUSD });
    }

    /// @inheritdoc ISablierMerkleFactoryBase
    function setMinFeeUSD(uint256 newMinFeeUSD) external override onlyAdmin {
        // Check: the new fee is not greater than the maximum allowed.
        if (newMinFeeUSD > MAX_FEE_USD) {
            revert Errors.SablierMerkleFactoryBase_MaxFeeUSDExceeded(newMinFeeUSD, MAX_FEE_USD);
        }

        // Effect: update the minimum fee.
        uint256 previousMinFeeUSD = minFeeUSD;
        minFeeUSD = newMinFeeUSD;

        // Log the update.
        emit SetMinFeeUSD({ admin: msg.sender, newMinFeeUSD: newMinFeeUSD, previousMinFeeUSD: previousMinFeeUSD });
    }

    /// @inheritdoc ISablierMerkleFactoryBase
    function setNativeToken(address newNativeToken) external override onlyAdmin {
        // Check: provided token is not zero address.
        if (newNativeToken == address(0)) {
            revert Errors.SablierMerkleFactoryBase_NativeTokenZeroAddress();
        }

        // Check: native token is not set.
        if (nativeToken != address(0)) {
            revert Errors.SablierMerkleFactoryBase_NativeTokenAlreadySet(nativeToken);
        }

        // Effect: set the native token.
        nativeToken = newNativeToken;

        // Log the update.
        emit SetNativeToken({ admin: msg.sender, nativeToken: newNativeToken });
    }

    /// @inheritdoc ISablierMerkleFactoryBase
    function setOracle(address newOracle) external override onlyAdmin {
        address previousOracle = oracle;

        // Effects: set the new oracle.
        _setOracle(newOracle);

        // Log the update.
        emit SetOracle({ admin: msg.sender, newOracle: newOracle, previousOracle: previousOracle });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks that the provided token is not the native token.
    /// @dev Reverts if the provided token is the native token.
    function _forbidNativeToken(address token) internal view {
        if (token == nativeToken) {
            revert Errors.SablierMerkleFactoryBase_ForbidNativeToken(token);
        }
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _minFeeUSDFor(address campaignCreator) internal view returns (uint256) {
        MerkleFactory.CustomFeeUSD memory customFee = _customFeesUSD[campaignCreator];
        return customFee.enabled ? customFee.fee : minFeeUSD;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          PRIVATE NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _setOracle(address newOracle) private {
        // Check: oracle implements the `latestRoundData` function.
        if (newOracle != address(0)) {
            AggregatorV3Interface(newOracle).latestRoundData();
        }

        // Effect: update the oracle.
        oracle = newOracle;
    }
}
