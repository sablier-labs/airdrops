# Archived

This repository is no longer maintained, and it is archived. The latest version of the airdrops protocol can be viewed
in the [evm-monorepo](https://github.com/sablier-labs/evm-monorepo/tree/main/airdrops).

# Sablier Airdrops [![Github Actions][gha-badge]][gha] [![Foundry][foundry-badge]][foundry] [![Twitter][twitter-badge]][twitter]

[gha]: https://github.com/sablier-labs/airdrops/actions
[gha-badge]: https://github.com/sablier-labs/airdrops/actions/workflows/ci.yml/badge.svg
[foundry]: https://getfoundry.sh
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[twitter-badge]: https://img.shields.io/twitter/follow/Sablier
[twitter]: https://x.com/Sablier

Sablier Airdrops is a collection of EVM smart contracts for distributing ERC-20 tokens via Merkle trees, with optional
vesting through the Sablier Lockup protocol.

## Introduction

Sablier Airdrops is a collection of smart contracts that allows airdrops of ERC-20 tokens using Merkle trees. It offers
multiple distributions options, including:

1. Instant airdrops: The simplest way to distribute tokens to a list of addresses. Eligible users can claim and receive
   their allocation instantly via a single claim transaction.
2. Vesting airdrops: This is the way to go if you want your users to receive tokens over time through vesting. Upon
   claiming, eligible users will have their tokens streamed through Sablier over a period specified by the campaign
   creator (aka the campaign owner). This distribution option has been referred to as Airstreams in the past.
3. Variable Claim Amount (VCA) airdrops: This distribution method allows the campaign creator to set up an airdrop with
   linear unlock. However, when a user claims their airdrop, any unvested tokens are forfeited and returned to the
   campaign creator. This approach is useful for airdrops aimed at rewarding loyal users who wait until the end of the
   unlock period to claim their tokens.

Sablier Airdrops also offer flexibility in configuring the Airdrop campaigns. For example, you can choose between
whether you want vesting to begin at the same time for all users (absolute) or at the time of each claim (relative).

## Links

- [Documentation](https://docs.sablier.com) — guides and technical details
- [Deployment addresses](https://docs.sablier.com/guides/airdrops/deployments)
- [Audits](https://github.com/sablier-labs/audits)
- [Changelog](./CHANGELOG.md)

## Security

The codebase has undergone rigorous audits by leading security experts from Cantina, as well as independent auditors.
For a comprehensive list of all audits conducted, please click [here](https://github.com/sablier-labs/audits).

For any security-related concerns, please refer to the [SECURITY](./SECURITY.md) policy.

## Contributing

Contributions are welcome. [Open](https://github.com/sablier-labs/airdrops/issues/new) an issue,
[start](https://github.com/sablier-labs/airdrops/discussions/new) a discussion, or submit a PR.

See [`AGENTS.md`](./AGENTS.md) for the development workflow, commands, and conventions.

## License

See [LICENSE.md](./LICENSE.md).
