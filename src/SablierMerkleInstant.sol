// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { SablierMerkleBase } from "./abstracts/SablierMerkleBase.sol";
import { ISablierMerkleInstant } from "./interfaces/ISablierMerkleInstant.sol";
import { Errors } from "./libraries/Errors.sol";
import { MerkleInstant } from "./types/DataTypes.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝

███╗   ███╗███████╗██████╗ ██╗  ██╗██╗     ███████╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ███╗   ██╗████████╗
████╗ ████║██╔════╝██╔══██╗██║ ██╔╝██║     ██╔════╝    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗████╗  ██║╚══██╔══╝
██╔████╔██║█████╗  ██████╔╝█████╔╝ ██║     █████╗      ██║██╔██╗ ██║███████╗   ██║   ███████║██╔██╗ ██║   ██║
██║╚██╔╝██║██╔══╝  ██╔══██╗██╔═██╗ ██║     ██╔══╝      ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║╚██╗██║   ██║
██║ ╚═╝ ██║███████╗██║  ██║██║  ██╗███████╗███████╗    ██║██║ ╚████║███████║   ██║   ██║  ██║██║ ╚████║   ██║
╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝

*/

/// @title SablierMerkleInstant
/// @notice See the documentation in {ISablierMerkleInstant}.
contract SablierMerkleInstant is
    ISablierMerkleInstant, // 2 inherited components
    SablierMerkleBase // 3 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Constructs the contract by initializing the immutable state variables.
    constructor(
        MerkleInstant.ConstructorParams memory params,
        address campaignCreator
    )
        SablierMerkleBase(
            campaignCreator,
            params.campaignName,
            params.expiration,
            params.initialAdmin,
            params.ipfsCID,
            params.merkleRoot,
            params.token
        )
    { }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleInstant
    function claim(
        uint256 index,
        address recipient,
        uint128 amount,
        bytes32[] calldata merkleProof
    )
        external
        payable
        override
    {
        // Check and Effect: Pre-process the claim parameters.
        _preProcessClaim(index, recipient, amount, merkleProof);

        // Interaction: Post-process the claim parameters.
        _postProcessClaim({ index: index, recipient: recipient, to: recipient, amount: amount });
    }

    /// @inheritdoc ISablierMerkleInstant
    function claimTo(
        uint256 index,
        address to,
        uint128 amount,
        bytes32[] calldata merkleProof
    )
        external
        payable
        override
    {
        // Check: `to` must not be the zero address.
        if (to == address(0)) {
            revert Errors.SablierMerkleBase_ToZeroAddress();
        }

        // Check and Effect: Pre-process the claim parameters.
        _preProcessClaim({ index: index, recipient: msg.sender, amount: amount, merkleProof: merkleProof });

        // Interaction: Post-process the claim parameters.
        _postProcessClaim({ index: index, recipient: msg.sender, to: to, amount: amount });
    }

    /*//////////////////////////////////////////////////////////////////////////
                          PRIVATE STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Post-processes the claim execution by handling the tokens transfer and emitting an event.
    function _postProcessClaim(uint256 index, address recipient, address to, uint128 amount) private {
        // Interaction: withdraw the tokens to the `to` address.
        TOKEN.safeTransfer(to, amount);

        // Log the claim.
        emit Claim(index, recipient, amount, to);
    }
}
