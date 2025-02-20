// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";
import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { ud } from "@prb/math/src/UD60x18.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { LockupNFTDescriptor } from "@sablier/lockup/src/LockupNFTDescriptor.sol";
import { SablierLockup } from "@sablier/lockup/src/SablierLockup.sol";
import { LockupTranched } from "@sablier/lockup/src/types/DataTypes.sol";
import { Merkle } from "murky/src/Merkle.sol";
import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactoryInstant } from "src/interfaces/ISablierMerkleFactoryInstant.sol";
import { ISablierMerkleFactoryLL } from "src/interfaces/ISablierMerkleFactoryLL.sol";
import { ISablierMerkleFactoryLT } from "src/interfaces/ISablierMerkleFactoryLT.sol";
import { ISablierMerkleFactoryVCA } from "src/interfaces/ISablierMerkleFactoryVCA.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { SablierMerkleFactoryInstant } from "src/SablierMerkleFactoryInstant.sol";
import { SablierMerkleFactoryLL } from "src/SablierMerkleFactoryLL.sol";
import { SablierMerkleFactoryLT } from "src/SablierMerkleFactoryLT.sol";
import { SablierMerkleFactoryVCA } from "src/SablierMerkleFactoryVCA.sol";
import { SablierMerkleInstant } from "src/SablierMerkleInstant.sol";
import { SablierMerkleLL } from "src/SablierMerkleLL.sol";
import { SablierMerkleLT } from "src/SablierMerkleLT.sol";
import { SablierMerkleVCA } from "src/SablierMerkleVCA.sol";
import { MerkleInstant, MerkleLL, MerkleLT, MerkleVCA } from "src/types/DataTypes.sol";
import { ERC20Mock } from "./mocks/erc20/ERC20Mock.sol";
import { Assertions } from "./utils/Assertions.sol";
import { Constants } from "./utils/Constants.sol";
import { DeployOptimized } from "./utils/DeployOptimized.sol";
import { MerkleBuilder } from "./utils/MerkleBuilder.sol";
import { Modifiers } from "./utils/Modifiers.sol";
import { Users } from "./utils/Types.sol";

/// @notice Base test contract with common logic needed by all tests.
abstract contract Base_Test is Assertions, Constants, DeployOptimized, Merkle, Modifiers {
    using MerkleBuilder for uint256[];

    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ERC20Mock internal dai;
    ISablierLockup internal lockup;
    ISablierMerkleFactoryInstant internal merkleFactoryInstant;
    ISablierMerkleFactoryLL internal merkleFactoryLL;
    ISablierMerkleFactoryLT internal merkleFactoryLT;
    ISablierMerkleFactoryVCA internal merkleFactoryVCA;
    ISablierMerkleInstant internal merkleInstant;
    ISablierMerkleLL internal merkleLL;
    ISablierMerkleLT internal merkleLT;
    ISablierMerkleVCA internal merkleVCA;

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

        // Deploy the Lockup contract.
        LockupNFTDescriptor nftDescriptor = new LockupNFTDescriptor();
        lockup = new SablierLockup(users.admin, nftDescriptor, 1000);

        // Deploy the Merkle Factory contracts.
        deployMerkleFactoriesConditionally();

        // Create users for testing.
        users.campaignOwner = createUser("CampaignOwner");
        users.eve = createUser("Eve");
        users.recipient = createUser("Recipient");
        users.recipient1 = createUser("Recipient1");
        users.recipient2 = createUser("Recipient2");
        users.recipient3 = createUser("Recipient3");
        users.recipient4 = createUser("Recipient4");
        users.sender = createUser("Sender");

        // Initialize the Merkle tree.
        initMerkleTree();

        // Set the variables in Modifiers contract.
        setVariables(users);

        // Set sender as the default caller for the tests.
        resetPrank({ msgSender: users.sender });

        // Warp to July 1, 2024 at 00:00 UTC to provide a more realistic testing environment.
        vm.warp({ newTimestamp: JULY_1_2024 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Approves all contracts to spend tokens from the address passed.
    function approveFactories(address from) internal {
        resetPrank({ msgSender: from });
        dai.approve({ spender: address(merkleFactoryInstant), value: MAX_UINT256 });
        dai.approve({ spender: address(merkleFactoryLL), value: MAX_UINT256 });
        dai.approve({ spender: address(merkleFactoryLT), value: MAX_UINT256 });
        dai.approve({ spender: address(merkleFactoryVCA), value: MAX_UINT256 });
    }

    /// @dev Generates a user, labels its address, funds it with test tokens, and approves the protocol contracts.
    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        deal({ token: address(dai), to: user, give: 1_000_000e18 });
        approveFactories({ from: user });
        return user;
    }

    /// @dev Deploys the Merkle Factory contracts conditionally based on the test profile.
    function deployMerkleFactoriesConditionally() internal {
        if (!isTestOptimizedProfile()) {
            merkleFactoryInstant = new SablierMerkleFactoryInstant(users.admin, MINIMUM_FEE);
            merkleFactoryLL = new SablierMerkleFactoryLL(users.admin, MINIMUM_FEE);
            merkleFactoryLT = new SablierMerkleFactoryLT(users.admin, MINIMUM_FEE);
            merkleFactoryVCA = new SablierMerkleFactoryVCA(users.admin, MINIMUM_FEE);
        } else {
            (merkleFactoryInstant, merkleFactoryLL, merkleFactoryLT, merkleFactoryVCA) =
                deployOptimizedMerkleFactories(users.admin, MINIMUM_FEE);
        }
        vm.label({ account: address(merkleFactoryInstant), newLabel: "MerkleFactoryInstant" });
        vm.label({ account: address(merkleFactoryLL), newLabel: "MerkleFactoryLL" });
        vm.label({ account: address(merkleFactoryLT), newLabel: "MerkleFactoryLT" });
        vm.label({ account: address(merkleFactoryVCA), newLabel: "MerkleFactoryVCA" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-BUILDER
    //////////////////////////////////////////////////////////////////////////*/

    function index1Proof() public view returns (bytes32[] memory) {
        return indexProof(INDEX1, users.recipient1);
    }

    function index2Proof() public view returns (bytes32[] memory) {
        return indexProof(INDEX2, users.recipient2);
    }

    function index3Proof() public view returns (bytes32[] memory) {
        return indexProof(INDEX3, users.recipient3);
    }

    function index4Proof() public view returns (bytes32[] memory) {
        return indexProof(INDEX4, users.recipient4);
    }

    function indexProof(uint256 index, address recipient) public view returns (bytes32[] memory) {
        uint256 leaf = MerkleBuilder.computeLeaf(index, recipient, CLAIM_AMOUNT);
        uint256 pos = Arrays.findUpperBound(LEAVES, leaf);
        return getProof(LEAVES.toBytes32(), pos);
    }

    /// @dev We need a separate function to initialize the Merkle tree because, at the construction time, the users are
    /// not yet set.
    function initMerkleTree() public {
        LEAVES[0] = MerkleBuilder.computeLeaf(INDEX1, users.recipient1, CLAIM_AMOUNT);
        LEAVES[1] = MerkleBuilder.computeLeaf(INDEX2, users.recipient2, CLAIM_AMOUNT);
        LEAVES[2] = MerkleBuilder.computeLeaf(INDEX3, users.recipient3, CLAIM_AMOUNT);
        LEAVES[3] = MerkleBuilder.computeLeaf(INDEX4, users.recipient4, CLAIM_AMOUNT);
        MerkleBuilder.sortLeaves(LEAVES);
        MERKLE_ROOT = getRoot(LEAVES.toBytes32());
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
            abi.encodeCall(ISablierMerkleBase.claim, (INDEX1, users.recipient1, CLAIM_AMOUNT, index1Proof()))
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  MERKLE-INSTANT
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleInstantAddress(
        address campaignCreator,
        address campaignOwner,
        uint40 expiration,
        bytes32 merkleRoot,
        IERC20 tokenAddress
    )
        internal
        view
        returns (address)
    {
        MerkleInstant.ConstructorParams memory params = merkleInstantConstructorParams({
            campaignOwner: campaignOwner,
            expiration: expiration,
            merkleRoot: merkleRoot,
            tokenAddress: tokenAddress
        });

        bytes32 salt = keccak256(abi.encodePacked(campaignCreator, abi.encode(params)));
        bytes32 creationBytecodeHash;

        if (!isTestOptimizedProfile()) {
            creationBytecodeHash =
                keccak256(bytes.concat(type(SablierMerkleInstant).creationCode, abi.encode(params, campaignCreator)));
        } else {
            creationBytecodeHash = keccak256(
                bytes.concat(
                    vm.getCode("out-optimized/SablierMerkleInstant.sol/SablierMerkleInstant.json"),
                    abi.encode(params, campaignCreator)
                )
            );
        }

        return vm.computeCreate2Address({
            salt: salt,
            initCodeHash: creationBytecodeHash,
            deployer: address(merkleFactoryInstant)
        });
    }

    function merkleInstantConstructorParams(
        address campaignOwner,
        uint40 expiration,
        bytes32 merkleRoot,
        IERC20 tokenAddress
    )
        public
        view
        returns (MerkleInstant.ConstructorParams memory)
    {
        return MerkleInstant.ConstructorParams({
            campaignName: CAMPAIGN_NAME,
            expiration: expiration,
            initialAdmin: campaignOwner,
            ipfsCID: IPFS_CID,
            merkleRoot: merkleRoot,
            token: tokenAddress
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LL
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleLLAddress(
        address campaignCreator,
        address campaignOwner,
        uint40 expiration,
        bytes32 merkleRoot,
        IERC20 tokenAddress
    )
        internal
        view
        returns (address)
    {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams({
            campaignOwner: campaignOwner,
            lockupAddress: lockup,
            expiration: expiration,
            merkleRoot: merkleRoot,
            tokenAddress: tokenAddress
        });
        bytes32 salt = keccak256(abi.encodePacked(campaignCreator, abi.encode(params)));

        bytes32 creationBytecodeHash;
        if (!isTestOptimizedProfile()) {
            creationBytecodeHash =
                keccak256(bytes.concat(type(SablierMerkleLL).creationCode, abi.encode(params, campaignCreator)));
        } else {
            creationBytecodeHash = keccak256(
                bytes.concat(
                    vm.getCode("out-optimized/SablierMerkleLL.sol/SablierMerkleLL.json"),
                    abi.encode(params, campaignCreator)
                )
            );
        }
        return vm.computeCreate2Address({
            salt: salt,
            initCodeHash: creationBytecodeHash,
            deployer: address(merkleFactoryLL)
        });
    }

    function merkleLLConstructorParams(
        address campaignOwner,
        uint40 expiration,
        ISablierLockup lockupAddress,
        bytes32 merkleRoot,
        IERC20 tokenAddress
    )
        public
        view
        returns (MerkleLL.ConstructorParams memory)
    {
        return MerkleLL.ConstructorParams({
            campaignName: CAMPAIGN_NAME,
            cancelable: CANCELABLE,
            expiration: expiration,
            initialAdmin: campaignOwner,
            ipfsCID: IPFS_CID,
            lockup: lockupAddress,
            merkleRoot: merkleRoot,
            schedule: MerkleLL.Schedule({
                startTime: ZERO,
                startPercentage: START_PERCENTAGE,
                cliffDuration: CLIFF_DURATION,
                cliffPercentage: CLIFF_PERCENTAGE,
                totalDuration: TOTAL_DURATION
            }),
            shape: SHAPE,
            token: tokenAddress,
            transferable: TRANSFERABLE
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LT
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleLTAddress(
        address campaignCreator,
        address campaignOwner,
        uint40 expiration,
        bytes32 merkleRoot,
        IERC20 tokenAddress
    )
        internal
        view
        returns (address)
    {
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams({
            campaignOwner: campaignOwner,
            lockupAddress: lockup,
            expiration: expiration,
            merkleRoot: merkleRoot,
            tokenAddress: tokenAddress
        });
        bytes32 salt = keccak256(abi.encodePacked(campaignCreator, abi.encode(params)));

        bytes32 creationBytecodeHash;
        if (!isTestOptimizedProfile()) {
            creationBytecodeHash =
                keccak256(bytes.concat(type(SablierMerkleLT).creationCode, abi.encode(params, campaignCreator)));
        } else {
            creationBytecodeHash = keccak256(
                bytes.concat(
                    vm.getCode("out-optimized/SablierMerkleLT.sol/SablierMerkleLT.json"),
                    abi.encode(params, campaignCreator)
                )
            );
        }

        return vm.computeCreate2Address({
            salt: salt,
            initCodeHash: creationBytecodeHash,
            deployer: address(merkleFactoryLT)
        });
    }

    function merkleLTConstructorParams(
        address campaignOwner,
        uint40 expiration,
        ISablierLockup lockupAddress,
        bytes32 merkleRoot,
        IERC20 tokenAddress
    )
        public
        view
        returns (MerkleLT.ConstructorParams memory)
    {
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages_ = new MerkleLT.TrancheWithPercentage[](2);
        tranchesWithPercentages_[0] =
            MerkleLT.TrancheWithPercentage({ unlockPercentage: ud2x18(0.2e18), duration: 2 days });
        tranchesWithPercentages_[1] =
            MerkleLT.TrancheWithPercentage({ unlockPercentage: ud2x18(0.8e18), duration: 8 days });

        return MerkleLT.ConstructorParams({
            campaignName: CAMPAIGN_NAME,
            cancelable: CANCELABLE,
            expiration: expiration,
            initialAdmin: campaignOwner,
            ipfsCID: IPFS_CID,
            lockup: lockupAddress,
            merkleRoot: merkleRoot,
            shape: SHAPE,
            streamStartTime: ZERO,
            token: tokenAddress,
            tranchesWithPercentages: tranchesWithPercentages_,
            transferable: TRANSFERABLE
        });
    }

    /// @dev Mirrors the logic from {SablierMerkleLT._calculateStartTimeAndTranches}.
    function tranchesMerkleLT(
        uint40 streamStartTime,
        uint128 totalAmount
    )
        public
        view
        returns (LockupTranched.Tranche[] memory tranches_)
    {
        tranches_ = new LockupTranched.Tranche[](2);
        if (streamStartTime == 0) {
            tranches_[0].timestamp = uint40(block.timestamp) + CLIFF_DURATION;
            tranches_[1].timestamp = uint40(block.timestamp) + TOTAL_DURATION;
        } else {
            tranches_[0].timestamp = streamStartTime + CLIFF_DURATION;
            tranches_[1].timestamp = streamStartTime + TOTAL_DURATION;
        }

        uint128 amount0 = ud(totalAmount).mul(ud(0.2e18)).intoUint128();
        uint128 amount1 = ud(totalAmount).mul(ud(0.8e18)).intoUint128();

        tranches_[0].amount = amount0;
        tranches_[1].amount = amount1;

        uint128 amountsSum = amount0 + amount1;

        if (amountsSum != totalAmount) {
            tranches_[1].amount += totalAmount - amountsSum;
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-VCA
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleVCAAddress(
        address campaignCreator,
        address campaignOwner,
        uint40 expiration,
        bytes32 merkleRoot,
        MerkleVCA.Timestamps memory timestamps,
        IERC20 tokenAddress
    )
        internal
        view
        returns (address)
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams({
            campaignOwner: campaignOwner,
            expiration: expiration,
            merkleRoot: merkleRoot,
            timestamps: timestamps,
            tokenAddress: tokenAddress
        });

        bytes32 salt = keccak256(abi.encodePacked(campaignCreator, abi.encode(params)));

        bytes32 creationBytecodeHash;
        if (!isTestOptimizedProfile()) {
            creationBytecodeHash =
                keccak256(bytes.concat(type(SablierMerkleVCA).creationCode, abi.encode(params, campaignCreator)));
        } else {
            creationBytecodeHash = keccak256(
                bytes.concat(
                    vm.getCode("out-optimized/SablierMerkleVCA.sol/SablierMerkleVCA.json"),
                    abi.encode(params, campaignCreator)
                )
            );
        }
        return vm.computeCreate2Address({
            salt: salt,
            initCodeHash: creationBytecodeHash,
            deployer: address(merkleFactoryVCA)
        });
    }

    function merkleVCAConstructorParams(
        address campaignOwner,
        uint40 expiration,
        bytes32 merkleRoot,
        MerkleVCA.Timestamps memory timestamps,
        IERC20 tokenAddress
    )
        public
        view
        returns (MerkleVCA.ConstructorParams memory)
    {
        return MerkleVCA.ConstructorParams({
            campaignName: CAMPAIGN_NAME,
            expiration: expiration,
            initialAdmin: campaignOwner,
            ipfsCID: IPFS_CID,
            merkleRoot: merkleRoot,
            timestamps: timestamps,
            token: tokenAddress
        });
    }

    function merkleVCATimestamps() public view returns (MerkleVCA.Timestamps memory) {
        return MerkleVCA.Timestamps({ start: RANGED_STREAM_START_TIME, end: RANGED_STREAM_END_TIME });
    }
}
