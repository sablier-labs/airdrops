# AGENTS.md

> [!NOTE]
>
> This repository is archived. Active development of the airdrops protocol continues in the
> [evm-monorepo](https://github.com/sablier-labs/evm-monorepo/tree/main/airdrops).

Guidance for agents and developers working in `@sablier/airdrops` — the EVM smart contracts of the Sablier Airdrops
protocol.

## Stack

- **Solidity** `0.8.29` (`evm_version = shanghai`), built with **Foundry**/Forge.
- **Bun** — package manager (`bun.lock`).
- **Just** — command runner; recipes are imported from `@sablier/devkit` (`just/evm.just`).
- **Solhint** + **Prettier** + **forge fmt** — linting and formatting.
- **Bulloak** — Branching Tree Technique (BTT) test scaffolding (`.tree` files).
- **Slither** — static analysis (`slither.config.json`).
- **Husky** + **lint-staged** — pre-commit hooks.
- Contract dependencies: OpenZeppelin Contracts `5.3.0`, PRBMath `4.1.0`, `@sablier/evm-utils` `1.0.3`,
  `@sablier/lockup` `3.0.1`.

## Commands

Recipes come from `@sablier/devkit`; run `just --list` for the full inventory. Aliases in parentheses.

### Setup

- `just install` (`i`) — install Node.js dependencies via Bun.
- `bun run setup` — install Husky git hooks (`setup` package script).

### Build

- `just build` (`b`) — compile contracts.
- `just build-optimized` (`bo`) — compile with the `optimized` profile (via-IR) into `out-optimized/`.
- `just clean` (`c`) — remove build artifacts.
- `just clean-modules` — remove `node_modules` recursively.

### Test

- `just test` (`t`) — run all tests (`forge test`); accepts extra args.
- `just test-lite` (`tl`) — run with the `lite` profile, skipping fork tests by default.
- `just test-optimized` (`to`) — run tests against the optimized build.
- `just test-bulloak` (`tb`) — verify test files match their `.tree` specs (BTT).
- `just coverage` (`cov`) — dump HTML coverage report.
- `just gas-report` (`gr`) — produce a gas report.

### Lint & format

- `just full-check` (`fc`) — run all checks (forge fmt, Solhint, Prettier).
- `just full-write` (`fw`) — apply all fixes.
- `just fmt-check` / `just fmt-write` — Forge formatter.
- `just solhint-check` (`sc`) / `just solhint-write` (`sw`) — Solhint on Solidity.
- `just prettier-check` (`pc`) / `just prettier-write` (`pw`) — Prettier on JSON/Markdown/YAML.

### Package scripts

- `bun run prepack` — install frozen deps and build distributable artifacts (`scripts/bash/prepare-artifacts.sh`).

## Architecture

Four campaign types, each paired with a factory that deploys campaign instances:

| Campaign             | Contract               | Distribution                                          |
| -------------------- | ---------------------- | ----------------------------------------------------- |
| Instant              | `SablierMerkleInstant` | One-shot claim of the full allocation.                |
| Linear Lockup (LL)   | `SablierMerkleLL`      | Vesting via a Sablier Lockup linear stream.           |
| Tranched Lockup (LT) | `SablierMerkleLT`      | Vesting via a Sablier Lockup tranched stream.         |
| VCA                  | `SablierMerkleVCA`     | Variable claim amount; unvested tokens are forfeited. |

- `src/` — entry contracts: `SablierFactoryMerkle{Instant,LL,LT,VCA}` and `SablierMerkle{Instant,LL,LT,VCA}`.
  - `abstracts/` — shared bases (`SablierFactoryMerkleBase`, `SablierMerkleBase`, `SablierMerkleLockup`).
  - `interfaces/` — public interfaces for every factory and campaign.
  - `libraries/` — `Errors`, `SignatureHash`.
  - `types/` — `DataTypes`.
- `tests/` — `unit/`, `integration/` (`concrete/` + `fuzz/`), `fork/`, with shared `utils/` and `Base.t.sol`.
- `scripts/solidity/` — Forge deployment (`Deploy*`) and campaign-creation (`CreateMerkle*`) scripts.
- `scripts/bash/` — artifact preparation for publishing.
- `out/` — Forge build output; `out-optimized/` — optimized-profile output.

### Foundry profiles (`foundry.toml`)

- `default` — optimizer on, 100M runs; 1000 fuzz runs.
- `lite` — optimizer off, 50 fuzz runs; fast local iteration (`FOUNDRY_PROFILE=lite`).
- `optimized` — via-IR production build into `out-optimized/`.
- `test-optimized` — run tests against the optimized build.

## Code Style

- Forge formatter (`[fmt]`): 120-char lines, 4-space tabs, double quotes, `long` int types, thousands underscores,
  multiline function headers.
- Solhint (`.solhint.json`): `solhint:recommended` plus overrides — max line length 128, code-complexity ≤ 9,
  `compiler-version >=0.8.22`.
- NatSpec on public/external APIs; revert reasons centralized in `src/libraries/Errors.sol`.
- Naming: contracts prefixed `Sablier`; interfaces prefixed `I`.

## Testing

- **Branching Tree Technique**: `.tree` files define test trees. Scaffold with `bulloak scaffold -wf <file>.tree` and
  verify alignment with `just test-bulloak`.
- Layered suites: `unit/`, `integration/concrete/`, `integration/fuzz/`, `fork/`.
- Keep coverage equal or higher (`just coverage`); provide gas snapshots for contract changes (`just gas-report`).

## Environment

Copy `.env.example` to `.env` and populate:

- `MNEMONIC` / `ETH_FROM` — deployer credentials.
- `ROUTEMESH_API_KEY` — RPC access (https://routeme.sh).
- `ETHERSCAN_API_KEY` — contract verification.
- `FOUNDRY_PROFILE` — e.g. `lite` for fast local runs.

## Consuming the package downstream

- Node.js: `bun add @sablier/airdrops` (or the npm/yarn/pnpm equivalent).
- Git submodule: `forge install sablier-labs/airdrops`, then install peer deps:
  `forge install sablier-labs/evm-utils@v1.0.0 OpenZeppelin/openzeppelin-contracts@v5.3.0 PaulRBerg/prb-math@v4.1.0 sablier-labs/lockup@v3.0.0`.

## Contribution Workflow

- Default branch: `main`. Open PRs against `staging` (the active development branch); `release` holds release commits.
- Pre-commit (lint-staged): Solhint `--fix` + `forge fmt` on `*.sol`; Prettier on `*.{json,md,yml}`.
- Before opening a PR: `just full-check` and `just test` pass, new tests cover new code paths, BTT trees are
  regenerated, and gas snapshots accompany contract changes.
- CI workflows: `ci.yml`, `ci-deep.yml`, `ci-fork.yml`, `ci-multibuild.yml`, `ci-slither.yml`.

> `CONTRIBUTING.md` is superseded by this file. Merge any remaining prerequisites/VSCode notes here, then delete it.
