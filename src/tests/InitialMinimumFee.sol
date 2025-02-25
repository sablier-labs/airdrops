// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

/// @notice A contract that stores the minimum fees for the supported chains and will be passed during factory
/// deployments.
contract InitialMinimumFee {
    /// @dev Chainlink format price.
    uint256 private ONE_DOLLAR = 1e8;

    mapping(uint256 chaindId => uint256 minimumFee) private _minimumFees;

    /// @dev Populate the minimum fee mapping for the supported chains.
    constructor() {
        // Ethereum Mainnet
        _minimumFees[1] = ONE_DOLLAR;
        // Arbitrum One
        _minimumFees[42_161] = ONE_DOLLAR;
        // Avalanche
        _minimumFees[43_114] = ONE_DOLLAR;
        // Base
        _minimumFees[8453] = ONE_DOLLAR;
        // BNB Smart Chain
        _minimumFees[56] = ONE_DOLLAR;
        // Gnosis Chain
        _minimumFees[100] = ONE_DOLLAR;
        // Linea
        _minimumFees[59_144] = ONE_DOLLAR;
        // Optimism
        _minimumFees[10] = ONE_DOLLAR;
        // Polygon
        _minimumFees[137] = ONE_DOLLAR;
        // Scroll
        _minimumFees[534_352] = ONE_DOLLAR;
        // zkSync Era
        _minimumFees[324] = ONE_DOLLAR;
    }

    /// @dev Defaults to zero if the chain is not supported.
    function getMinimumFee() public view returns (uint256) {
        return _minimumFees[block.chainid];
    }
}
