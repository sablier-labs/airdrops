# See https://github.com/sablier-labs/devkit/blob/main/just/evm.just
# Run just --list to see all available commands
import "./node_modules/@sablier/devkit/just/evm.just"

default:
  @just --list

build-optimized *args:
  FOUNDRY_PROFILE=optimized forge build {{ args }}

test *args:
  forge test --nmc ChainlinkOracle_Fork_Test {{ args }}

test-lite *args:
  FOUNDRY_PROFILE=lite forge test --no-match-test "testFork" {{ args }}