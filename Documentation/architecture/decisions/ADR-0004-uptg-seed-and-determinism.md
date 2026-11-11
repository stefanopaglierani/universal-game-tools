# ADR-0004: UPTG seed handling and determinism guarantee

**Status:** Accepted
**Date:** 2026-11-06
**Module:** UPTG

## Context

Generation must be reproducible from a seed. Using one seed for every noise layer correlates them, `seed` shadows a GDScript global function, and `FastNoiseLite` stores seeds in 32 bits.

## Options considered

1. One seed for everything: simple / correlated layers, name clash.
2. `generation_seed` plus per-stage sub-seeds from a documented integer hash, local RNGs only: independent layers, stable across engine versions / a small amount of code to maintain.

## Decision

Option 2. `generation_seed` is limited to 0–2147483647; sub-seeds come from `derive(seed, salt)` (architecture §7.2) with fixed salts; global RNG functions are forbidden in the addon; `String.hash()`/`hash()` are not used. Guarantee: identical output for the same configuration, seed, Godot build and platform; cross-platform identity is a goal, not a guarantee. `ALGORITHM_VERSION` is recorded in the terrain data. Decided by Stefano, 2026-11-06.

## Consequences

Milestone 0 confirmed the 31-bit limit (a seed of 3000000000 wraps to -1294967296 in `FastNoiseLite`) and that the GDScript implementation of `derive()` matches four independently computed test vectors.

Source: `UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.md`
