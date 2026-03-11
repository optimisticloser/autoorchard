# AGENTS.md — autoorchard

## Project snapshot

`autoorchard` is a Swift-first framework for autonomous experimentation on local AI pipelines on Apple platforms.

This project is inspired by Andrej Karpathy's `autoresearch`, but it targets **product pipelines**, not tiny-model training loops.

Primary domains:
- Vision / OCR pipelines
- Foundation Models prompt and policy surfaces
- routing / fallback logic
- ranking / reranking logic
- simulator / device-backed evaluation loops

The flagship example is **Split Receipt Lab**.
The second example is **Music Genie Rank Lab**.

## Core thesis

The framework should make local AI product optimization feel like a disciplined lab:

1. mutate one bounded surface
2. run a fixed evaluation budget
3. compute a score
4. keep wins
5. revert losses
6. append to a ledger

The harness is the judge.
The model is not the judge.

## Current stage

The repository already has:
- Swift Package setup
- `AutoOrchardCore`
- `autoorchard` CLI with `doctor` and `init-lab`
- README and architecture docs
- a detailed `IMPLEMENTATION_PLAN.md`
- example Split and Music Genie lab docs

The most important missing capabilities are:
- a real experiment runner
- score comparison against a baseline
- Git-backed keep/revert
- a working flagship Split Receipt Lab harness

## Immediate implementation priorities

### Priority 1
Build the real experiment loop:
- scenario manifest loading
- evaluator protocol(s)
- score contract(s)
- baseline and candidate runs
- ledger entries for all runs

### Priority 2
Add Git-backed keep/revert so accepted changes persist and regressions roll back safely.

### Priority 3
Build Split Receipt Lab v0.1 as the first true end-to-end proof of the framework.

## Rules for agents

### 1) Do not over-generalize early
A strong working Split lab is worth far more than a broad but hollow framework.

### 2) Keep the mutable surface intentionally small
The first labs should mutate one clearly bounded strategy surface, not the whole app.

### 3) Prefer inspectable systems over magic
If a design choice makes the experiment loop harder to reason about, it is probably wrong for v1.

### 4) Keep Cupertino optional
Cupertino is the preferred exact-documentation backend for Apple APIs, but it must remain an optional provider, not a hard dependency for the core runtime.

### 5) The harness judges the experiment
Foundation Models may help propose changes or analyze outputs, but final keep/revert decisions should be driven by a stable score contract.

### 6) Preserve Apple-native taste
This should feel like an Apple developer tool, not a Python framework awkwardly translated into Swift.

## Repo map

- `Package.swift` — package definition
- `README.md` — public landing narrative
- `IMPLEMENTATION_PLAN.md` — source-of-truth implementation plan
- `program.md` — high-level project strategy
- `Sources/AutoOrchardCore/` — core types and library implementation
- `Sources/autoorchard/` — CLI executable
- `Tests/AutoOrchardCoreTests/` — tests for core behavior
- `docs/` — design and architecture docs
- `Examples/` — flagship lab examples and program files

## Commands

### Build
```bash
swift build
```

### Test
```bash
swift test
```

### Doctor
```bash
swift run autoorchard doctor
```

### Scaffold lab
```bash
swift run autoorchard init-lab /tmp/MyLab receipt-pipeline
```

## Implementation guidance by area

- If changing core abstractions, keep naming tight and boring.
- If changing the CLI, prefer a small command surface over feature sprawl.
- If changing docs, optimize for outside open-source readers who do not know Split or 2tap.
- If building the first real lab, optimize for reproducibility and score clarity before speed.

## What good progress looks like

Good progress is:
- one real evaluator
- one score contract
- one bounded mutation surface
- one baseline run
- one candidate run
- one ledger entry proving the loop is real

Bad progress is:
- endless architecture abstraction
- broad plugin systems without a real lab
- vague support for every Apple AI API with no flagship demo

## If you are Codex / an implementation agent

Start by reading:
1. `README.md`
2. `IMPLEMENTATION_PLAN.md`
3. `docs/architecture.md`
4. `docs/karpathy-comparison.md`
5. `docs/split-receipt-lab.md`

Then work in this order unless told otherwise:
1. experiment runner
2. keep/revert
3. Split Receipt Lab harness
4. docs/readme polish

Always run tests after meaningful changes.
Prefer small coherent commits.
