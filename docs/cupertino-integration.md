# Cupertino integration

`autoorchard` treats [Cupertino](https://github.com/mihaelamj/cupertino) as the preferred exact-documentation backend for Apple APIs.

## Why Cupertino

When autonomous agents are modifying Swift code that depends on:

- Vision
- Foundation Models
- Core ML
- SwiftUI
- device tooling

hallucinated documentation is poison.

Cupertino gives:
- local indexed Apple docs
- deterministic search
- MCP support
- CLI/JSON workflows

## Current v0 stance

This repository does **not** bundle Cupertino.
Instead, it assumes Cupertino may already be installed locally.

The `doctor` command checks for the `cupertino` binary.

## Intended workflow

An autonomous lab can use Cupertino to:
- retrieve exact API docs before proposing a mutation
- verify platform availability
- inspect related sample code and HIG guidance
- keep Apple-native experiments grounded in real APIs

## Future direction

Later versions may include:
- a `DocumentationProvider` backed by Cupertino CLI
- structured Apple API retrieval during experiment planning
- Cupertino-backed scenario metadata generation
