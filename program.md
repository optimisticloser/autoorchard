# autoorchard default program

This repository is building an Apple-native autonomous experimentation framework.

The core idea is simple:

- mutate one bounded surface
- run a fixed evaluation budget
- score the outcome
- keep improvements
- revert regressions
- repeat

## Constraints

- Prefer small, composable Swift abstractions over broad framework sprawl.
- Avoid magic. Make experiments inspectable and ledger-backed.
- Keep Cupertino as the preferred exact-documentation path for Apple framework lookups.
- Do not over-generalize early. A strong flagship lab is worth more than vague flexibility.

## Immediate v0 objective

Build the cleanest possible foundation for:
- Split Receipt Lab
- Music Genie Rank Lab

Both should feel like first-class examples of the same core loop.
