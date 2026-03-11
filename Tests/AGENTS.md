# AGENTS.md — Tests

Tests in autoorchard should protect the experiment loop, not just syntactic behavior.

## Focus

Prioritize tests for:
- stable score calculation
- deterministic ledger output
- scenario loading
- baseline/candidate comparison behavior
- keep/revert safety when implemented

## Rule

If a feature is central to the experiment loop, it should have a direct test before the framework grows wider.
