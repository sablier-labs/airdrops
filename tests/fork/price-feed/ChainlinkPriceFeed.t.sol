// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { stdJson } from "forge-std/src/StdJson.sol";

import { SablierMerkleFactoryInstant } from "src/SablierMerkleFactoryInstant.sol";
import { ChainlinkPriceFeedAddresses } from "src/tests/ChainlinkPriceFeedAddresses.sol";

import { Base_Test } from "../../Base.t.sol";

contract ChainlinkPriceFeed_ForkTest is Base_Test, ChainlinkPriceFeedAddresses {
    using stdJson for string;

    string internal tokenPricesJson;

    /// @dev Run the Python script to get the token prices from CoinGecko API.
    function setUp() public override {
        Base_Test.setUp();

        string[] memory inputs = new string[](2);
        inputs[0] = "python";
        inputs[1] = "tests/fork/price-feed/get_token_prices.py";
        tokenPricesJson = string(vm.ffi(inputs));
    }

    /// @dev We need to re-deploy the contracts on each forked chain.
    modifier initTest(string memory chainName) {
        vm.createSelectFork({ urlOrAlias: chainName });
        merkleFactoryInstant = new SablierMerkleFactoryInstant(users.admin, getPriceFeedAddress(), MINIMUM_FEE);
        merkleInstant = merkleFactoryInstant.createMerkleInstant(
            merkleInstantConstructorParams(), AGGREGATE_AMOUNT, RECIPIENT_COUNT
        );
        _;
    }

    function testFork_PriceFeed_Mainnet() external initTest("mainnet") {
        _test_PriceFeed({ tokenName: "ethereum" });
    }

    // function testFork_PriceFeed_Arbitrum() external initTest("arbitrum") {
    //     _test_PriceFeed({ tokenName: "ethereum" });
    // }

    // function testFork_PriceFeed_Avalanche() external initTest("avalanche") {
    //     _test_PriceFeed({ tokenName: "avalanche" });
    // }

    function testFork_PriceFeed_Base() external initTest("base") {
        _test_PriceFeed({ tokenName: "ethereum" });
    }

    function testFork_PriceFeed_BNB() external initTest("bnb") {
        _test_PriceFeed({ tokenName: "bnb" });
    }

    function testFork_PriceFeed_Gnosis() external initTest("gnosis") {
        _test_PriceFeed({ tokenName: "dai" });
    }

    function testFork_PriceFeed_Linea() external initTest("linea") {
        _test_PriceFeed({ tokenName: "ethereum" });
    }

    // function testFork_PriceFeed_Optimism() external initTest("optimism") {
    //     _test_PriceFeed({ tokenName: "ethereum" });
    // }

    // function testFork_PriceFeed_Polygon() external initTest("polygon") {
    //     _test_PriceFeed({ tokenName: "polygon" });
    // }

    function testFork_PriceFeed_Scroll() external initTest("scroll") {
        _test_PriceFeed({ tokenName: "ethereum" });
    }

    function _test_PriceFeed(string memory tokenName) private view {
        uint256 expectedFeeInWei = tokenPricesJson.readUint(string.concat(".", tokenName));
        uint256 actualFeeInWei = merkleInstant.calculateMinimumFeeInWei();

        // Assert the actual fee is within 1.5% of the expected fee.
        uint256 tolerance = actualFeeInWei * 15 / 1000;
        assertApproxEqAbs(actualFeeInWei, expectedFeeInWei, tolerance, "fee");
    }
}
