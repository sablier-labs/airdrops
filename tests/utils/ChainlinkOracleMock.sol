// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

/// @notice A mock Chainlink oracle contract that returns $3000 price with 8 decimals.
contract ChainlinkOracleMock {
    function decimals() external pure returns (uint8) {
        return 8;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 3000e8, 0, block.timestamp, 0);
    }
}

/// @notice A mock Chainlink oracle contract with an outdated `updatedAt` timestamp.
contract ChainlinkOracleOutdated {
    function decimals() external pure returns (uint8) {
        return 8;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 3000e8, 0, block.timestamp - 86_401, 0);
    }
}

/// @notice A mock Chainlink oracle contract with `updatedAt` timestamp in the future.
contract ChainlinkOracleUpdatedInFuture {
    function decimals() external pure returns (uint8) {
        return 8;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 3000e8, 0, block.timestamp + 1, 0);
    }
}

/// @notice A mock Chainlink oracle contract that returns $3000 price with 18 decimals.
contract ChainlinkOracleWith18Decimals {
    function decimals() external pure returns (uint8) {
        return 18;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 3000e18, 0, block.timestamp, 0);
    }
}

/// @notice A mock Chainlink oracle contract that returns $3000 price with 6 decimals.
contract ChainlinkOracleWith6Decimals {
    function decimals() external pure returns (uint8) {
        return 6;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 3000e6, 0, block.timestamp, 0);
    }
}

/// @notice A mock Chainlink oracle that does not implement the `latestRoundData` function.
contract ChainlinkOracleWithoutImpl { }

/// @notice A mock Chainlink oracle contract that returns a 0 price.
contract ChainlinkOracleWithZeroPrice {
    function decimals() external pure returns (uint8) {
        return 8;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 0, 0, block.timestamp, 0);
    }
}
