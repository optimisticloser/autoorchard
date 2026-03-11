# AGENTS.md — Sources

This folder contains the actual implementation.

## Guiding principle

Keep the core small, explicit, and inspectable.
This is not the place for framework maximalism.

## Folder roles

- `AutoOrchardCore/` — reusable library logic
- `autoorchard/` — CLI entrypoints and command wiring

## Coding rules

- prefer small types and protocols over giant manager classes
- name things around the experiment loop: Scenario, Evaluator, Score, Budget, Ledger, MutationSurface
- avoid overfitting the API to Split alone, but do use Split as the sanity test
- do not introduce async complexity unless the experiment flow clearly needs it
- do not hide Git behavior behind opaque abstractions

## First implementation target

The next meaningful code here should make baseline/candidate experiment runs real.
If a change does not bring that loop closer, question it.
