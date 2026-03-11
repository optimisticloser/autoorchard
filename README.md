# autoorchard

**Autoresearch for local AI pipelines on Apple platforms.**

`autoorchard` is a Swift-first framework and CLI for autonomous experimentation on Apple-native AI product pipelines.

Instead of manually bouncing between hunches, prompts, heuristics, OCR tweaks, routing rules, and evaluation spreadsheets, `autoorchard` turns product experimentation into a disciplined loop:

1. change one bounded thing
2. run a fixed evaluation budget
3. score the result
4. keep wins
5. revert losses
6. repeat

The project is inspired by Andrej Karpathy's [`autoresearch`](https://github.com/karpathy/autoresearch), but aimed at a different problem space:

- **not** training tiny LLMs on NVIDIA GPUs
- **yes** improving real local AI pipelines on Apple platforms
- **yes** using the tools Apple gives you: Vision / OCR, Foundation Models, Core ML, simulators, device runners, and Swift modules

## Why this exists

The hardest part of Apple-native AI product work is not always model availability.
It is the endless loop of:

- tweak OCR grouping
- tweak prompt strategy
- tweak fallback behavior
- tweak candidate scoring
- rerun the same receipts or ranking evals
- compare manually
- forget why the last version won

`autoorchard` exists to systematize that loop.

## Design principles

### 1) Small mutable surface
Autonomous experimentation works best when the agent can mutate a **small, explicit** part of the system.

### 2) Fixed evaluation budget
Every experiment should run against the same scenario set and the same scoring contract.

### 3) Keep / revert discipline
The framework should help you keep improvements and revert regressions automatically.

### 4) Product pipelines, not only model training
This project is meant for things like:

- receipt parsing pipelines
- OCR normalization
- Foundation Models prompting policies
- routing and fallback rules
- ranking / reranking policies
- local AI planner behavior

### 5) Exact Apple documentation via Cupertino
`autoorchard` treats [Cupertino](https://github.com/mihaelamj/cupertino) as the preferred documentation backend for exact Apple framework lookups. Cupertino is not bundled here, but this project is designed to work alongside it.

## What is in v0

This repository starts with:

- `AutoOrchardCore`: core types for scenarios, evaluators, scores, budgets, ledgers, and mutation plans
- `autoorchard`: a lightweight CLI with:
  - `doctor` — checks local Apple tooling and Cupertino availability
  - `init-lab` — scaffolds a lab with a `program.md`, ledger, scenarios folder, and config
- example labs for:
  - `SplitReceiptLab`
  - `MusicGenieRankLab`
- detailed docs that map the Karpathy idea into Apple-native product pipelines

This is intentionally a **clean v0**, not the final system.

## Quick start

### Requirements

- macOS 15+
- Swift 6+
- Xcode command line tools

Optional but recommended:

- [Cupertino](https://github.com/mihaelamj/cupertino) for exact Apple docs

### Build

```bash
swift build
```

### Check your environment

```bash
swift run autoorchard doctor
```

### Scaffold a new lab

```bash
swift run autoorchard init-lab /tmp/ReceiptLab receipt-pipeline
```

This creates:

- `program.md`
- `Config/lab.json`
- `Ledger/results.tsv`
- `Scenarios/`
- `MutableSurface/README.md`

## Example use cases

### Split

- OCR line grouping experiments
- receipt parser fidelity improvements
- candidate scoring / selection
- abstention and review-before-save policy tuning
- fail-closed/manual fallback policy tuning

### Music Genie

- planner prompt policy tuning
- retrieval routing policy tuning
- ranking / reranking policy experiments
- explanation legibility tests
- ambiguity handling / fallback experiments

## Why not just use `autoresearch-mlx` directly?

Because the brilliance of Karpathy's project is mostly in the **structure**, not the specific training code.

`autoresearch-mlx` is excellent proof that fixed-budget autonomous research can run locally on Apple Silicon, but it is still a framework for **model training experiments**.

`autoorchard` is aimed at a different category:

- product pipelines
- evaluation harnesses
- routing logic
- prompts
- heuristics
- local runtime behavior

So the plan here is:

- take the *shape* of Karpathy's system
- keep the elegance
- apply it to Apple-native app pipelines in Swift

## Roadmap

See:

- [`docs/vision.md`](docs/vision.md)
- [`docs/architecture.md`](docs/architecture.md)
- [`docs/karpathy-comparison.md`](docs/karpathy-comparison.md)
- [`docs/cupertino-integration.md`](docs/cupertino-integration.md)
- [`docs/roadmap.md`](docs/roadmap.md)
- [`docs/split-receipt-lab.md`](docs/split-receipt-lab.md)

## Long-term thesis

Karpathy showed that research can become a disciplined overnight loop.

`autoorchard` aims to show that **local AI product optimization on Apple platforms** can become that kind of loop too.
