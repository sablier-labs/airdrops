// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { SablierMerkleFactoryBase } from "./abstracts/SablierMerkleFactoryBase.sol";
import { ISablierMerkleFactoryInstant } from "./interfaces/ISablierMerkleFactoryInstant.sol";
import { ISablierMerkleInstant } from "./interfaces/ISablierMerkleInstant.sol";
import { SablierMerkleInstant } from "./SablierMerkleInstant.sol";
import { MerkleInstant } from "./types/DataTypes.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗     ███╗   ███╗███████╗██████╗ ██╗  ██╗██╗     ███████╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗    ████╗ ████║██╔════╝██╔══██╗██║ ██╔╝██║     ██╔════╝
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝    ██╔████╔██║█████╗  ██████╔╝█████╔╝ ██║     █████╗
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗    ██║╚██╔╝██║██╔══╝  ██╔══██╗██╔═██╗ ██║     ██╔══╝
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║    ██║ ╚═╝ ██║███████╗██║  ██║██║  ██╗███████╗███████╗
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝

███████╗ █████╗  ██████╗████████╗ ██████╗ ██████╗ ██╗   ██╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ███╗   ██╗████████╗
██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗╚██╗ ██╔╝    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗████╗  ██║╚══██╔══╝
█████╗  ███████║██║        ██║   ██║   ██║██████╔╝ ╚████╔╝     ██║██╔██╗ ██║███████╗   ██║   ███████║██╔██╗ ██║   ██║
██╔══╝  ██╔══██║██║        ██║   ██║   ██║██╔══██╗  ╚██╔╝      ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║╚██╗██║   ██║
██║     ██║  ██║╚██████╗   ██║   ╚██████╔╝██║  ██║   ██║       ██║██║ ╚████║███████║   ██║   ██║  ██║██║ ╚████║   ██║
╚═╝     ╚═╝  ╚═╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝       ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝

*/

/// @title SablierMerkleFactoryInstant
/// @notice See the documentation in {ISablierMerkleFactoryInstant}.
contract SablierMerkleFactoryInstant is ISablierMerkleFactoryInstant, SablierMerkleFactoryBase {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialMinFeeUSD The initial min USD fee charged for claiming an airdrop.
    /// @param initialOracle The initial oracle contract address.
    constructor(
        address initialAdmin,
        uint256 initialMinFeeUSD,
        address initialOracle
    )
        SablierMerkleFactoryBase(initialAdmin, initialMinFeeUSD, initialOracle)
    { }

    /*//////////////////////////////////////////////////////////////////////////
                                NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleFactoryInstant
    function createMerkleInstant(
        MerkleInstant.ConstructorParams memory params,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        override
        returns (ISablierMerkleInstant merkleInstant)
    {
        // Check: user-provided token is not the native token.
        _forbidNativeToken(address(params.token));

        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, abi.encode(params)));

        // Deploy the MerkleInstant contract with CREATE2.
        merkleInstant = new SablierMerkleInstant{ salt: salt }({ params: params, campaignCreator: msg.sender });

        // Log the creation of the MerkleInstant contract, including some metadata that is not stored on-chain.
        emit CreateMerkleInstant({
            merkleInstant: merkleInstant,
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount,
            minFeeUSD: _minFeeUSDFor(msg.sender),
            oracle: oracle
        });
    }
}
