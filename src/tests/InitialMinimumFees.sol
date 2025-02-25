// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

/// @notice A contract that stores the minimum fees for the supported chains and will be passed during factory
/// deployments.
contract InitialMinimumFees {
    /// @dev Chainlink format price.
    uint256 private THREE_DOLLARS = 3e8;

    mapping(uint256 chaindId => uint256 minimumFee) private _minimumFees;

    /// @dev Populate the minimum fee mapping for the supported chains.
    constructor() {
        // Ethereum Mainnet
        _minimumFees[1] = THREE_DOLLARS;
        // Arbitrum One
        _minimumFees[42_161] = THREE_DOLLARS;
        // Avalanche
        _minimumFees[43_114] = THREE_DOLLARS;
        // Base
        _minimumFees[8453] = THREE_DOLLARS;
        // BNB Smart Chain
        _minimumFees[56] = THREE_DOLLARS;
        // Gnosis Chain
        _minimumFees[100] = THREE_DOLLARS;
        // Linea
        _minimumFees[59_144] = THREE_DOLLARS;
        // Optimism
        _minimumFees[10] = THREE_DOLLARS;
        // Polygon
        _minimumFees[137] = THREE_DOLLARS;
        // Scroll
        _minimumFees[534_352] = THREE_DOLLARS;
        // zkSync Era
        _minimumFees[324] = THREE_DOLLARS;
    }

    /// @dev Defaults to zero if the chain is not supported.
    function getMinimumFee() public view returns (uint256) {
        return _minimumFees[block.chainid];
    }
}
