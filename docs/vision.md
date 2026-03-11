# Vision

`swift-autolab` is an attempt to do for Apple-native AI product pipelines what `autoresearch` did for tiny-model training loops: turn intuition-heavy experimentation into a repeatable, inspectable, fixed-budget system.

## Thesis

Local AI on Apple platforms is constrained in all the right ways:

- models are smaller
- APIs are opinionated
- latency matters
- device behavior matters
- heuristics matter
- product polish matters

That makes Apple-native AI a perfect environment for **autonomous experimentation over pipelines**, not just over model weights.

## What should become easier

Without a framework like this, product teams end up doing endless back-and-forth:

- tweak a Vision OCR policy
- tweak a Foundation Models prompt
- tweak a ranking weight
- rerun a handful of scenarios
- forget why a previous version won
- repeat

With `swift-autolab`, the loop should become:

- define the mutation surface
- define the scenario set
- define the score
- run a bounded experiment
- keep wins, revert losses
- preserve the ledger

## Why open source

This should not only work for Split or Music Genie.
If done well, it should be useful anywhere people are trying to make local AI on Apple platforms more capable without relying on giant cloud models or unstructured prompt tinkering.
