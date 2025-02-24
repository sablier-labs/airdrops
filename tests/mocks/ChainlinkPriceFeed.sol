// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

contract ChainlinkPriceFeed {
    /// @dev The price returned by Chainlink if the ETH price were to be $3000.
    int256 private constant ONE_DOLLAR_IN_ETH = 300_000_000_000;

    function latestRoundData()
        external
        pure
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, ONE_DOLLAR_IN_ETH, 0, 0, 0);
    }
}
