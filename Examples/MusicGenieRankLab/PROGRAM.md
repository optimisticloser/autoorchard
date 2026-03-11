# Music Genie Rank Lab program

Goal: improve planner and ranking behavior for local recommendation flows without increasing drift or explanation nonsense.

## Rules

- mutate only bounded planner / ranking surfaces
- run a fixed eval set
- keep improvements that raise fit while preserving constraint satisfaction
- revert regressions or fragile wins
- use Cupertino for exact Apple API and framework references

## Primary score dimensions

- ranking fit
- constraint satisfaction
- diversity without drift
- explanation legibility
