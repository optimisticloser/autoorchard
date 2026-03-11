# Relationship to Karpathy's autoresearch

This project is deeply inspired by Andrej Karpathy's `autoresearch`.

## What we are keeping

- `program.md` as strategy surface
- one or a few bounded mutable surfaces
- fixed-budget experiment loops
- explicit score comparison
- keep / revert discipline
- experiment ledger

## What changes for Apple-native pipelines

Karpathy's setup is about training a small model.
`swift-autolab` is about improving **product pipelines** built with Apple technologies.

That means the mutable surface may be:

- OCR normalization strategy
- Foundation Models prompt policy
- fallback policy
- candidate scoring logic
- routing logic
- ranking policy

It is not limited to training loops.

## The biggest translation

In `autoresearch`, the experiment loop optimizes a model by training it for a fixed time budget.

In `swift-autolab`, the experiment loop optimizes an Apple-native product pipeline by running a fixed set of scenarios and comparing the result to a stable score contract.
