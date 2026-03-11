# Architecture

## Core abstractions

### Scenario
A reproducible product case that can be evaluated.

Examples:
- one receipt fixture
- one ranking request + expected tracks
- one fallback path

### Evaluator
Runs a scenario against the current mutable surface and returns one or more raw measurements.

### Score
Normalizes evaluator outputs into a comparable result.

### Budget
Defines how much experimentation can happen in a single pass.

Examples:
- 1 eval pass
- 20 scenarios
- 5 minutes wall clock

### MutationSurface
The bounded area the agent is allowed to change.

Examples:
- one Swift strategy file
- one prompt template
- one config table
- one ranking policy object

### Ledger
Append-only record of experiments, outcomes, and keep/revert decisions.

## Loop

1. propose mutation
2. apply mutation to bounded surface
3. run evaluator(s)
4. compute score
5. compare to best known result
6. keep or revert
7. write ledger entry

## Principle

The agent is not the judge.
The harness is the judge.
