// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { LockupNFTDescriptor } from "@sablier/lockup/src/LockupNFTDescriptor.sol";
import { SablierLockup } from "@sablier/lockup/src/SablierLockup.sol";
import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactory } from "src/interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { SablierMerkleFactory } from "src/SablierMerkleFactory.sol";
import { SablierMerkleInstant } from "src/SablierMerkleInstant.sol";
import { SablierMerkleLL } from "src/SablierMerkleLL.sol";
import { SablierMerkleLT } from "src/SablierMerkleLT.sol";
import { MerkleInstant, MerkleLL, MerkleLT } from "src/types/DataTypes.sol";
import { ERC20Mock } from "./mocks/erc20/ERC20Mock.sol";
import { Assertions } from "./utils/Assertions.sol";
import { Constants } from "./utils/Constants.sol";
import { Defaults } from "./utils/Defaults.sol";
import { DeployOptimized } from "./utils/DeployOptimized.sol";
import { Modifiers } from "./utils/Modifiers.sol";
import { Users } from "./utils/Types.sol";

/// @notice Base test contract with common logic needed by all tests.
abstract contract Base_Test is Assertions, Constants, DeployOptimized, Modifiers {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ERC20Mock internal dai;
    Defaults internal defaults;
    ISablierLockup internal lockup;
    ISablierMerkleFactory internal merkleFactory;
    ISablierMerkleInstant internal merkleInstant;
    ISablierMerkleLL internal merkleLL;
    ISablierMerkleLT internal merkleLT;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        // Deploy the base test contracts.
        dai = new ERC20Mock("Dai Stablecoin", "DAI");

        // Label the base test contracts.
        vm.label({ account: address(dai), newLabel: "DAI" });

        // Create the protocol admin.
        users.admin = payable(makeAddr({ name: "Admin" }));
        vm.startPrank({ msgSender: users.admin });

        // Deploy the defaults contract.
        defaults = new Defaults();

        // Deploy the Lockup contract.
        LockupNFTDescriptor nftDescriptor = new LockupNFTDescriptor();
        lockup = new SablierLockup(users.admin, nftDescriptor, 1000);

        // Deploy the Merkle Factory.
        deployMerkleFactoryConditionally();

        // Set the default fee on the Merkle factory.
        merkleFactory.setDefaultFee(defaults.FEE());

        // Create users for testing.
        users.campaignOwner = createUser("CampaignOwner");
        users.eve = createUser("Eve");
        users.recipient = createUser("Recipient");
        users.recipient1 = createUser("Recipient1");
        users.recipient2 = createUser("Recipient2");
        users.recipient3 = createUser("Recipient3");
        users.recipient4 = createUser("Recipient4");
        users.sender = createUser("Sender");

        defaults.setUsers(users);
        defaults.initMerkleTree();

        // Set the variables in Modifiers contract.
        setVariables(defaults, users);

        // Set sender as the default caller for the tests.
        resetPrank({ msgSender: users.sender });

        // Warp to July 1, 2024 at 00:00 UTC to provide a more realistic testing environment.
        vm.warp({ newTimestamp: JULY_1_2024 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Approves all contracts to spend tokens from the address passed.
    function approveFactory(address from) internal {
        resetPrank({ msgSender: from });
        dai.approve({ spender: address(merkleFactory), value: MAX_UINT256 });
    }

    /// @dev Generates a user, labels its address, funds it with test tokens, and approves the protocol contracts.
    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        deal({ token: address(dai), to: user, give: 1_000_000e18 });
        approveFactory({ from: user });
        return user;
    }

    /// @dev Deploys the Merkle Factory contract conditionally based on the test profile.
    function deployMerkleFactoryConditionally() internal {
        // Deploy the Merkle Factory.
        if (!isTestOptimizedProfile()) {
            merkleFactory = new SablierMerkleFactory(users.admin);
        } else {
            merkleFactory = deployOptimizedMerkleFactory(users.admin);
        }
        vm.label({ account: address(merkleFactory), newLabel: "MerkleFactory" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CALL EXPECTS - IERC20
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a call to {IERC20.transfer}.
    function expectCallToTransfer(address to, uint256 value) internal {
        vm.expectCall({ callee: address(dai), data: abi.encodeCall(IERC20.transfer, (to, value)) });
    }

    /// @dev Expects a call to {IERC20.transfer}.
    function expectCallToTransfer(IERC20 token, address to, uint256 value) internal {
        vm.expectCall({ callee: address(token), data: abi.encodeCall(IERC20.transfer, (to, value)) });
    }

    /// @dev Expects a call to {IERC20.transferFrom}.
    function expectCallToTransferFrom(address from, address to, uint256 value) internal {
        vm.expectCall({ callee: address(dai), data: abi.encodeCall(IERC20.transferFrom, (from, to, value)) });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            CALL EXPECTS - MERKLE LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a call to {ISablierMerkleBase.claim} with data provided.
    function expectCallToClaimWithData(
        address merkleLockup,
        uint256 fee,
        uint256 index,
        address recipient,
        uint128 amount,
        bytes32[] memory merkleProof
    )
        internal
    {
        vm.expectCall(
            merkleLockup, fee, abi.encodeCall(ISablierMerkleBase.claim, (index, recipient, amount, merkleProof))
        );
    }

    /// @dev Expects a call to {ISablierMerkleBase.claim} with msgValue as `msg.value`.
    function expectCallToClaimWithMsgValue(address merkleLockup, uint256 msgValue) internal {
        vm.expectCall(
            merkleLockup,
            msgValue,
            abi.encodeCall(
                ISablierMerkleBase.claim,
                (defaults.INDEX1(), users.recipient1, defaults.CLAIM_AMOUNT(), defaults.index1Proof())
            )
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                HELPERS - MERKLE LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleInstantAddress(
        uint256 aggregateAmount,
        address campaignCreator,
        address campaignOwner,
        uint40 expiration,
        bytes32 merkleRoot,
        uint256 recipientCount,
        IERC20 token_
    )
        internal
        view
        returns (address)
    {
        MerkleInstant.CreateParams memory createParams = defaults.merkleInstantCreateParams({
            aggregateAmount: aggregateAmount,
            campaignOwner: campaignOwner,
            expiration: expiration,
            merkleRoot: merkleRoot,
            recipientCount: recipientCount,
            token_: token_
        });

        bytes32 salt = keccak256(abi.encodePacked(campaignCreator, abi.encode(createParams)));
        bytes32 creationBytecodeHash;

        if (!isTestOptimizedProfile()) {
            creationBytecodeHash = keccak256(
                bytes.concat(type(SablierMerkleInstant).creationCode, abi.encode(createParams, campaignCreator))
            );
        } else {
            creationBytecodeHash = keccak256(
                bytes.concat(
                    vm.getCode("out-optimized/SablierMerkleInstant.sol/SablierMerkleInstant.json"),
                    abi.encode(createParams, campaignCreator)
                )
            );
        }

        return vm.computeCreate2Address({
            salt: salt,
            initCodeHash: creationBytecodeHash,
            deployer: address(merkleFactory)
        });
    }

    function computeMerkleLLAddress(
        uint256 aggregateAmount,
        address campaignCreator,
        address campaignOwner,
        uint40 expiration,
        bytes32 merkleRoot,
        uint256 recipientCount,
        IERC20 token_
    )
        internal
        view
        returns (address)
    {
        MerkleLL.CreateParams memory createParams = defaults.merkleLLCreateParams({
            aggregateAmount: aggregateAmount,
            campaignOwner: campaignOwner,
            lockup: lockup,
            expiration: expiration,
            merkleRoot: merkleRoot,
            recipientCount: recipientCount,
            token_: token_
        });
        bytes32 salt = keccak256(abi.encodePacked(campaignCreator, abi.encode(createParams)));

        bytes32 creationBytecodeHash;
        if (!isTestOptimizedProfile()) {
            creationBytecodeHash =
                keccak256(bytes.concat(type(SablierMerkleLL).creationCode, abi.encode(createParams, campaignCreator)));
        } else {
            creationBytecodeHash = keccak256(
                bytes.concat(
                    vm.getCode("out-optimized/SablierMerkleLL.sol/SablierMerkleLL.json"),
                    abi.encode(createParams, campaignCreator)
                )
            );
        }
        return vm.computeCreate2Address({
            salt: salt,
            initCodeHash: creationBytecodeHash,
            deployer: address(merkleFactory)
        });
    }

    function computeMerkleLTAddress(
        uint256 aggregateAmount,
        address campaignCreator,
        address campaignOwner,
        uint40 expiration,
        bytes32 merkleRoot,
        uint256 recipientCount,
        IERC20 token_
    )
        internal
        view
        returns (address)
    {
        MerkleLT.CreateParams memory createParams = defaults.merkleLTCreateParams({
            aggregateAmount: aggregateAmount,
            campaignOwner: campaignOwner,
            lockup: lockup,
            expiration: expiration,
            merkleRoot: merkleRoot,
            recipientCount: recipientCount,
            token_: token_
        });
        bytes32 salt = keccak256(abi.encodePacked(campaignCreator, abi.encode(createParams)));

        bytes32 creationBytecodeHash;
        if (!isTestOptimizedProfile()) {
            creationBytecodeHash =
                keccak256(bytes.concat(type(SablierMerkleLT).creationCode, abi.encode(createParams, campaignCreator)));
        } else {
            creationBytecodeHash = keccak256(
                bytes.concat(
                    vm.getCode("out-optimized/SablierMerkleLT.sol/SablierMerkleLT.json"),
                    abi.encode(createParams, campaignCreator)
                )
            );
        }

        return vm.computeCreate2Address({
            salt: salt,
            initCodeHash: creationBytecodeHash,
            deployer: address(merkleFactory)
        });
    }
}
