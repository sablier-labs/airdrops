// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { BaseScript } from "script/Base.sol";
import { SablierMerkleFactoryInstant } from "src/SablierMerkleFactoryInstant.sol";

import { Base_Test } from "./../../Base.t.sol";

contract ChainlinkOracle_ForkTest is BaseScript, Base_Test {
    /// @dev We need to re-deploy the contracts on each forked chain.
    modifier initTest(string memory chainName) {
        vm.createSelectFork({ urlOrAlias: chainName });
        merkleFactoryInstant = new SablierMerkleFactoryInstant(users.admin, initialMinimumFee(), chainlinkOracle());
        merkleInstant = merkleFactoryInstant.createMerkleInstant(
            merkleInstantConstructorParams(), AGGREGATE_AMOUNT, RECIPIENT_COUNT
        );
        _;
    }

    function testFork_PriceFeed_Mainnet() external initTest("mainnet") {
        _test_PriceFeed();
    }

    function testFork_PriceFeed_Arbitrum() external initTest("arbitrum") {
        _test_PriceFeed();
    }

    function testFork_PriceFeed_Avalanche() external initTest("avalanche") {
        _test_PriceFeed();
    }

    function testFork_PriceFeed_Base() external initTest("base") {
        _test_PriceFeed();
    }

    function testFork_PriceFeed_BNB() external initTest("bnb") {
        _test_PriceFeed();
    }

    function testFork_PriceFeed_Gnosis() external initTest("gnosis") {
        _test_PriceFeed();
    }

    function testFork_PriceFeed_Linea() external initTest("linea") {
        _test_PriceFeed();
    }

    function testFork_PriceFeed_Optimism() external initTest("optimism") {
        _test_PriceFeed();
    }

    function testFork_PriceFeed_Polygon() external initTest("polygon") {
        _test_PriceFeed();
    }

    function testFork_PriceFeed_Scroll() external initTest("scroll") {
        _test_PriceFeed();
    }

    function _test_PriceFeed() private view {
        uint256 actualFeeInWei = merkleInstant.minimumFeeInWei();
        assertGt(actualFeeInWei, 0, "minimum fee in wei");
    }
}
