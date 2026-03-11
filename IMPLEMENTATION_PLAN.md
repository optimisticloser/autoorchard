# Implementation Plan — autoorchard

**Project**: autoorchard  
**Version**: v0.1  
**Status**: Ready for implementation  
**Timeline**: 3–5 weeks for a meaningful v1  
**Last updated**: 2026-03-11

---

## 1) Vision and Context

### Current Problem

#### Who feels this pain
- **Solo Apple-native AI builders** shipping local AI features with Vision, Foundation Models, and Core ML
- **Small product teams** that keep manually tuning OCR, prompts, routing logic, fallback behavior, and ranking rules
- **Open-source Swift developers** who want local AI experimentation without adopting a Python-first, GPU-first research stack
- **2tap itself** via Split and Music Genie, where product quality increasingly depends on repeated, disciplined experimentation rather than one-off intuition

#### What happens today

Improving local AI product behavior is usually messy.

Teams do some version of this:
- tweak OCR grouping or normalization
- tweak prompt shape or extraction policy
- tweak abstention/fallback rules
- rerun a handful of cases manually
- compare by memory or vibes
- forget why the last version won
- accidentally regress a protected baseline while fixing an edge case

That process can work, but it does not scale well.
It is expensive in attention, hard to reproduce, and difficult to hand off.

#### Measurable impact
- **Experiment overhead**: high setup cost for every parser / ranking iteration
- **Regression risk**: improvements in weak cases often break previously good cases
- **Low reproducibility**: product teams rarely preserve experiment history in a clean ledger
- **High cognitive load**: too much back-and-forth thinking is spent rediscovering the same problem shape

#### How to measure the current problem
- time spent per experiment loop
- number of manual steps required to compare two candidate behaviors
- number of regressions introduced while fixing edge cases
- number of experiments whose rationale cannot be reconstructed later

---

### Proposed Solution

Build **autoorchard**, a Swift-first framework for autonomous experimentation on local AI pipelines on Apple platforms.

The core idea is simple:

1. define a **bounded mutable surface**
2. define a **fixed scenario set**
3. define a **score contract**
4. run a **fixed-budget experiment loop**
5. **keep** improvements
6. **revert** regressions
7. preserve everything in a **ledger**

This is inspired by Andrej Karpathy’s `autoresearch`, but aimed at a different problem category.

Karpathy’s version focuses on training-loop research.
`autoorchard` focuses on **product pipeline research**:
- OCR + parsing
- Foundation Models prompt policy
- routing and fallback rules
- ranking / reranking behavior
- planner behavior
- simulator/device-backed scenario evaluation

The long-term ambition is to make Apple-native AI product optimization feel as disciplined and repeatable as a small research lab.

---

### Hypotheses (what must be true)

- **H1**: If local AI experimentation is turned into a fixed-budget, ledger-backed loop, then teams can improve product behavior faster than manual back-and-forth iteration.
- **H2**: If the mutable surface is kept intentionally small, then even non-frontier local models can produce useful autonomous improvements when judged by a strong harness.
- **H3**: If the framework is Swift-first and Apple-native, then Apple developers will find it meaningfully more usable than Python-first research tooling for product pipeline work.
- **H4**: A strong flagship use case (Split Receipt Lab) will make the general framework legible and compelling to the open-source community.
- **H5**: Cupertino-style exact Apple documentation access materially improves the reliability of autonomous experiment design and code mutation on Apple APIs.

---

## 2) Scope for v0 / v1

### Core v0 capabilities

- [ ] **Core experiment abstractions**: Scenario, Evaluator, Score, Budget, Ledger, MutationSurface
- [ ] **CLI**: `doctor`, `init-lab`, and basic experiment-scaffolding workflow
- [ ] **Ledger format**: append-only experiment ledger with stable machine-readable output
- [ ] **Lab scaffolding**: create `program.md`, config, scenarios folder, mutable surface folder, and results ledger
- [ ] **Project docs**: vision, architecture, Karpathy comparison, Cupertino integration, roadmap
- [ ] **Example labs**: Split Receipt Lab and Music Genie Rank Lab documentation + scaffolds

### v1 capabilities (meaningful first implementation)

- [ ] **Real experiment runner**: run baseline and candidate evaluations from the CLI
- [ ] **Keep / revert flow**: use Git-backed state transitions for experiment decisions
- [ ] **Scenario manifest format**: structured definitions for reproducible runs
- [ ] **Score aggregation**: weighted multi-dimensional score calculation
- [ ] **Split Receipt Lab harness**: first real working flagship lab
- [ ] **Cupertino doc provider integration**: optional exact Apple docs lookup during experiment setup or mutation planning

### Out of scope for the first real release

- [ ] full distributed orchestration
- [ ] cluster scheduling
- [ ] generalized remote cloud agents
- [ ] UI dashboard
- [ ] embeddings-based clustering of experiment families
- [ ] direct model fine-tuning support as the main story
- [ ] trying to support every Apple AI API from day one

### Success metrics

#### Adoption / project fit
- the framework can run one real Split experiment end-to-end
- the framework can be understood from README + docs without private context
- at least one external Apple developer can understand the value proposition quickly

#### Quality
- a flagship lab can preserve a protected baseline while improving at least one weak case
- experiment results are reproducible and ledger-backed
- git keep/revert leaves a clean history of accepted vs rejected changes

#### Open-source impact
- project thesis is legible and differentiated from generic AI tooling
- the Split showcase is concrete enough to make the framework feel real
- the architecture is general enough that other Apple-native pipeline use cases feel plausible

---

## 3) Technology Stack

### Primary stack

| Layer | Technology | Version / Target | Purpose |
|------|------------|------------------|---------|
| Language | Swift | 6.x | Core implementation language |
| Package Manager | SwiftPM | current | Build, modularization, tests |
| CLI | Swift executable target | current | Local runner and lab tooling |
| Platform | macOS | 15+ | Primary host environment |
| Apple Tooling | xcrun / xcodebuild | Xcode 16+ | Device and simulator integration |
| Docs Provider | Cupertino (optional) | latest | Exact Apple documentation lookup |
| Version Control | Git | current | Keep / revert, provenance, experiment history |
| Data format | JSON / TSV / Markdown | - | Config, ledger, docs, scenario manifests |

### Apple-native integrations expected later

| Domain | Apple Technology | Purpose |
|--------|------------------|---------|
| OCR / text extraction | Vision | Receipt and document pipelines |
| Local LLM behavior | Foundation Models | Prompt policy, planner behavior, local reasoning surfaces |
| Device / simulator orchestration | xcrun / CoreDevice / simctl | Scenario execution |
| Local ML components | Core ML | Optional scorer / classifier / reranker surfaces |

### Alternative stack choices (if needed later)

- small Python glue scripts for legacy harnesses, but only at the edges
- SQLite for richer experiment ledgers later
- Swift Argument Parser if CLI complexity grows past the current minimal setup

---

## 4) Conceptual Data Architecture

This project is not a CRUD app in the usual sense, but it still has a clean data model.

### Core entities

```text
[Lab] 1---* [Scenario]
  |
  *---* [ExperimentRun]
  |
  *---* [LedgerEntry]
  |
  *---1 [MutationSurface]
  |
  *---1 [ScoreContract]
```

### Main types

#### `Lab`

```swift
struct Lab {
  let name: String
  let kind: String
  let documentationProvider: String
  let budget: ExperimentBudget
}
```

#### `Scenario`

```swift
struct Scenario {
  let id: String
  let kind: String
  let fixturePath: String
  let expectedPath: String?
  let tags: [String]
}
```

#### `ExperimentRun`

```swift
struct ExperimentRun {
  let id: String
  let labName: String
  let startedAt: Date
  let finishedAt: Date?
  let candidateSummary: String
  let decision: RunDecision
}
```

#### `LedgerEntry`

```swift
struct LedgerEntry {
  let timestamp: Date
  let decision: Decision   // baseline | keep | revert | crash | note
  let summary: String
  let score: ScoreBreakdown?
  let notes: [String]
}
```

#### `ScoreBreakdown`

```swift
struct ScoreBreakdown {
  let dimensions: [String: Double]
  let total: Double
}
```

### Relationships

- one `Lab` has many `Scenarios`
- one `Lab` has many `ExperimentRuns`
- one `Lab` has many `LedgerEntry` rows
- one `Lab` has one primary `MutationSurface`
- one `Lab` has one `ScoreContract`

---

## 5) Implementation Modules

### Status legend

- ⬜ Not started
- 🟡 In progress
- ✅ Completed

---

### MODULE 1: Project Foundation and Documentation

**Status:** 🟡 In progress  
**Priority:** CRITICAL  
**Dependencies:** None  
**Estimate:** 1–2 days

#### Objective

Establish a public, legible open-source foundation with the correct thesis, naming, architecture framing, and initial Swift package structure.

#### Deliverables

- [x] public GitHub repository created
- [x] project renamed to `autoorchard`
- [x] Swift Package base structure
- [x] minimal CLI (`doctor`, `init-lab`)
- [x] core docs in English
- [x] example lab scaffolds for Split and Music Genie
- [ ] add CONTRIBUTING.md
- [ ] add issue templates and basic GitHub labels
- [ ] add stronger README example showing one concrete Split experiment lifecycle

#### Files

**Created / maintained:**
- `Package.swift`
- `README.md`
- `program.md`
- `docs/vision.md`
- `docs/architecture.md`
- `docs/karpathy-comparison.md`
- `docs/cupertino-integration.md`
- `docs/roadmap.md`
- `docs/split-receipt-lab.md`

#### Prompt for agent

```text
CONTEXT:
Project: autoorchard
Goal: a Swift-first framework for autonomous experimentation on local AI pipelines on Apple platforms.
Stage: public v0 foundation.

TASK:
1. Keep the project thesis sharp and differentiated from generic AI tooling.
2. Preserve the Karpathy-inspired structure, but adapt it to Apple-native product pipelines.
3. Prefer simple, elegant abstractions and English documentation.
4. Avoid feature sprawl and fake completeness.

REQUIREMENTS:
- README must explain the value without private context.
- Docs must clearly state that Cupertino is an optional exact-docs provider, not the core runtime.
- Split Receipt Lab must feel like the flagship example.

DO NOT:
- add broad infrastructure before the experiment loop exists
- make the project sound like another generic agent framework
```

---

### MODULE 2: Real Experiment Runner

**Status:** ⬜ Not started  
**Priority:** CRITICAL  
**Dependencies:** Module 1  
**Estimate:** 2–3 days

#### Objective

Move from “thesis + scaffolding” to a real Karpathy-style loop that can run an experiment, compute a score, and record a decision.

#### Deliverables

- [ ] `run-baseline` CLI command
- [ ] `run-candidate` CLI command
- [ ] result comparison against best known baseline
- [ ] stable output format for score + per-dimension breakdown
- [ ] ledger append on every run
- [ ] crash handling with explicit ledger entries

#### Suggested files

**Create:**
- `Sources/AutoOrchardCore/ExperimentRunner.swift`
- `Sources/AutoOrchardCore/ScoreContract.swift`
- `Sources/AutoOrchardCore/ScenarioManifest.swift`
- `Sources/autoorchard/Commands/RunBaselineCommand.swift`
- `Sources/autoorchard/Commands/RunCandidateCommand.swift`

#### Business rules

1. The runner must treat the harness as the judge, not the LLM.
2. A candidate run must be directly comparable to the baseline.
3. The ledger must remain append-only.
4. Reproducibility matters more than speed in the first implementation.

#### Prompt for agent

```text
CONTEXT:
This module is the heart of autoorchard.
We already have docs and scaffolding; now we need the actual experiment loop.

TASK:
Build a first real experiment runner that:
- loads a lab config
- loads scenarios
- runs an evaluator
- computes a score
- compares the result with the current best known state
- writes a ledger entry

REQUIREMENTS:
- output must be deterministic enough for repeated local comparison
- keep the abstractions small
- design the APIs around product-pipeline evaluation, not only model training
- do not over-generalize into a huge plugin framework yet

DO NOT:
- add distributed orchestration
- add UI
- assume Foundation Models are the judge
```

---

### MODULE 3: Git-backed Keep / Revert

**Status:** ⬜ Not started  
**Priority:** HIGH  
**Dependencies:** Module 2  
**Estimate:** 1–2 days

#### Objective

Bring one of the most powerful parts of Karpathy’s pattern into autoorchard: accepted improvements stick, regressions roll back cleanly.

#### Deliverables

- [ ] experiment workspace state capture
- [ ] keep decision writes a clean commit or patch artifact
- [ ] revert decision restores prior state safely
- [ ] basic provenance note for each kept result
- [ ] optional “manual review required” mode before commit

#### Suggested files

**Create:**
- `Sources/AutoOrchardCore/GitWorkspace.swift`
- `Sources/AutoOrchardCore/KeepRevertPolicy.swift`
- `docs/git-flow.md`

#### Rules

1. Auto-revert must be reliable before auto-keep becomes ambitious.
2. Kept changes should carry enough metadata to understand why they won.
3. The feature should work in a normal local Git repo without requiring GitHub APIs.

#### Prompt for agent

```text
CONTEXT:
The experiment loop is not compelling yet without keep/revert discipline.
This module should make autoorchard feel much closer to autoresearch in spirit.

TASK:
Implement a safe Git-backed keep/revert layer for experiment candidates.

REQUIREMENTS:
- prefer safety and clarity over cleverness
- a failed experiment should leave the repo in a known-good state
- a kept experiment should be easy to inspect later

DO NOT:
- hide Git operations behind too much magic
- assume every user wants automatic pushes or PRs
```

---

### MODULE 4: Cupertino Documentation Provider

**Status:** ⬜ Not started  
**Priority:** HIGH  
**Dependencies:** Module 1  
**Estimate:** 1–2 days

#### Objective

Use Cupertino as the preferred exact Apple-docs backend so experiments touching Vision, Foundation Models, Core ML, or device tooling can be grounded in real Apple APIs.

#### Deliverables

- [ ] Cupertino availability check richer than current `doctor`
- [ ] small wrapper around the Cupertino CLI
- [ ] ability to retrieve and cache exact API references for experiment planning
- [ ] docs showing how labs should use Cupertino without depending on it at runtime

#### Suggested files

**Create:**
- `Sources/AutoOrchardCore/DocumentationProvider.swift`
- `Sources/AutoOrchardCore/CupertinoProvider.swift`
- `docs/cupertino-workflows.md`

#### Rules

1. Cupertino should remain optional.
2. autoorchard should degrade gracefully if Cupertino is absent.
3. Documentation access is a support system for the lab, not the lab itself.

#### Prompt for agent

```text
CONTEXT:
Apple-native experimentation is brittle without exact docs.
Cupertino already solves Apple documentation retrieval extremely well.

TASK:
Create a clean optional integration so autoorchard can use Cupertino for exact API documentation.

REQUIREMENTS:
- do not bundle Cupertino into the core project
- treat it as a documentation provider
- make the integration easy to understand from the README and docs

DO NOT:
- turn this into a general MCP framework
- make Cupertino a hard dependency for using autoorchard
```

---

### MODULE 5: Split Receipt Lab v0.1 (Flagship)

**Status:** ⬜ Not started  
**Priority:** CRITICAL  
**Dependencies:** Modules 2, 3, 4  
**Estimate:** 3–5 days

#### Objective

Create the first real working lab that proves the framework matters.

This is the flagship use case.
If this is weak, the whole project feels theoretical.

#### Scope

The first Split lab should be intentionally narrow:
- restaurant-style receipts
- parser fidelity
- protected baselines
- truthful abstention and review behavior

#### Deliverables

- [ ] fixed scenario set for a first receipt corpus
- [ ] score contract for item fidelity / subtotal / total / abstention
- [ ] one clearly bounded mutable surface
- [ ] baseline run recorded in ledger
- [ ] at least one candidate experiment path
- [ ] docs showing what improved and what remained unproven

#### Suggested mutable surfaces

Start with one of these, not all at once:
- `ReceiptParsingStrategy.swift`
- `ReceiptNormalizationPolicy.swift`
- `ReceiptCandidateScorer.swift`

#### Suggested score dimensions

- item fidelity
- subtotal fidelity
- total fidelity
- service charge fidelity
- truthful abstention
- correction burden proxy

#### Prompt for agent

```text
CONTEXT:
This module is the flagship demonstration of autoorchard.
It should prove the framework can improve a real Apple-native product pipeline, not just describe one.

TASK:
Build Split Receipt Lab v0.1 with:
- a fixed receipt scenario set
- a score contract
- one bounded mutable surface
- baseline run support
- candidate run support
- ledger-backed results

REQUIREMENTS:
- keep the first lab narrow and honest
- protect known-good baselines
- do not widen the claim to every receipt type
- treat Foundation Models as a possible helper, not the final judge

DO NOT:
- solve every parser problem at once
- conflate simulator confidence with distributed-build confidence
- build a generic plugin system before the first lab works
```

---

### MODULE 6: Music Genie Rank Lab v0.1

**Status:** ⬜ Not started  
**Priority:** MEDIUM  
**Dependencies:** Modules 2, 3, 4  
**Estimate:** 2–4 days

#### Objective

Prove the framework generalizes beyond receipt parsing.

#### Scope

Use a bounded music-planning or ranking problem:
- prompt/planner policy
- retrieval routing
- reranking weights
- explanation legibility

#### Deliverables

- [ ] fixed ranking / recommendation scenario set
- [ ] score contract for fit, constraint satisfaction, and drift
- [ ] one bounded mutable surface
- [ ] baseline + candidate experiment support

#### Prompt for agent

```text
CONTEXT:
Music Genie is the second demonstration that autoorchard is a framework, not a one-off Split tool.

TASK:
Design a narrow rank/planner lab for Music Genie that is scoreable and reproducible.

REQUIREMENTS:
- prioritize ranking fit and constraint satisfaction over vague creativity
- keep the first mutation surface small
- avoid fully open-ended LLM judging
```

---

### MODULE 7: README Showcase and Open-Source Polish

**Status:** ⬜ Not started  
**Priority:** HIGH  
**Dependencies:** Modules 2 and 5  
**Estimate:** 1–2 days

#### Objective

Turn the project from “interesting repo” into “repo people immediately want to try.”

#### Deliverables

- [ ] README narrative upgraded with concrete flagship demo
- [ ] quickstart for Split Receipt Lab
- [ ] architecture diagram
- [ ] CONTRIBUTING.md
- [ ] issue templates
- [ ] sample experiment transcript or ledger excerpt
- [ ] clearer positioning against `autoresearch` and against generic AI orchestration tools

#### Prompt for agent

```text
CONTEXT:
Open-source traction will come from clarity and taste, not just features.

TASK:
Make the project legible, exciting, and concrete for outside Swift/Apple developers.

REQUIREMENTS:
- keep the README direct and strong
- anchor the story in one real flagship use case
- explain why this is not just another AI agent framework
```

---

## 6) Suggested Directory Evolution

### Current

```text
autoorchard/
  Package.swift
  README.md
  program.md
  Sources/
  Tests/
  docs/
  Examples/
```

### Target after v1

```text
autoorchard/
  Package.swift
  README.md
  program.md
  IMPLEMENTATION_PLAN.md
  Sources/
    AutoOrchardCore/
    autoorchard/
  Tests/
  docs/
  Examples/
    SplitReceiptLab/
      PROGRAM.md
      Config/
      Scenarios/
      MutableSurface/
      Ledger/
    MusicGenieRankLab/
      PROGRAM.md
      Config/
      Scenarios/
      MutableSurface/
      Ledger/
```

---

## 7) Testing Plan

### Core tests

- [ ] score breakdown math is stable
- [ ] ledger serialization is stable
- [ ] scenario manifest loading is deterministic
- [ ] budget enforcement behaves correctly
- [ ] failed runs still write useful crash notes to the ledger

### Git flow tests

- [ ] keep commits the intended change
- [ ] revert restores the previous known-good state
- [ ] dirty working tree warnings behave correctly

### Cupertino integration tests

- [ ] doctor reports Cupertino availability correctly
- [ ] Cupertino wrapper returns structured doc output when present
- [ ] the system degrades gracefully when Cupertino is absent

### Split lab tests

- [ ] baseline receipts score as expected
- [ ] a known-bad mutation lowers the score
- [ ] a known-good mutation can improve at least one weak case without breaking the protected baseline

---

## 8) Deployment and Rollout

This is an open-source Swift package, so “deployment” is mainly release discipline.

### Phase 1 — foundation release
- tag first public repo state
- make README and docs coherent
- ensure `swift build` and `swift test` pass cleanly

### Phase 2 — first working lab release
- land Split Receipt Lab v0.1
- document one end-to-end experiment loop
- publish a small demo or walkthrough

### Phase 3 — ecosystem credibility
- add Music Genie Rank Lab
- improve Cupertino integration
- gather early external feedback from Swift/Apple devs

---

## 9) Risks and Mitigations

### Risk 1: Over-generalizing too early
**Problem:** The project becomes a vague framework instead of a compelling system.

**Mitigation:** Keep Split Receipt Lab as the flagship and optimize for one real working loop first.

### Risk 2: Letting the model judge itself
**Problem:** Foundation Models become both proposer and evaluator, creating circular nonsense.

**Mitigation:** Treat the harness and score contract as the primary judge. Use Foundation Models as helpers, not final arbiters.

### Risk 3: Too much mutable surface
**Problem:** The agent touches too much code and produces noisy or irreproducible changes.

**Mitigation:** Start with one bounded mutable surface per lab.

### Risk 4: Cupertino becoming a hidden hard dependency
**Problem:** The project stops being usable unless Cupertino is installed.

**Mitigation:** Keep Cupertino optional and treat it as a doc provider only.

### Risk 5: Weak open-source positioning
**Problem:** The project reads like another generic AI framework.

**Mitigation:** Anchor every piece of public communication in a strong concrete Apple-native use case.

---

## 10) Open Questions

- How much of the first keep/revert flow should be automatic vs review-gated?
- Should scenario manifests stay JSON-first, YAML-first, or Swift-coded?
- What is the right first mutation surface for Split?
- When should device-backed evaluation enter the loop instead of simulator-only or harness-only evaluation?
- Should Foundation Models proposal logic live inside the core package or in lab-specific adapters?
- How far should Cupertino integration go before it starts bloating the project?

---

## 11) Recommended Immediate Next Steps

### This week
1. build Module 2 (real experiment runner)
2. build Module 3 (keep/revert)
3. define the first Split Receipt Lab scenario set
4. define the first Split score contract

### Immediately after
5. land Module 5 (Split Receipt Lab v0.1)
6. upgrade README with a real flagship walkthrough
7. add Cupertino wrapper as optional provider

### Only after that
8. generalize more aggressively
9. add Music Genie Rank Lab
10. push toward stronger overnight autonomy

---

## 12) Philosophy: why this plan matters

The real opportunity behind autoorchard is not “AI agents but in Swift.”

It is this:

**local AI app optimization on Apple platforms can become a disciplined, inspectable research loop instead of an endless manual tuning ritual.**

That is the thing worth building.

This implementation plan exists to keep that thesis sharp while turning it into something real.
