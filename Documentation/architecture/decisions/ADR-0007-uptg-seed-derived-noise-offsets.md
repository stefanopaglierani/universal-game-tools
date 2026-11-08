**English** | [Italiano](ADR-0007-uptg-seed-derived-noise-offsets.it.md)

# ADR-0007: UPTG noise sampling offsets derived from the seed

**Status:** Accepted
**Date:** 2026-11-06
**Module:** UPTG

## Context

During Milestone A, simplex noise turned out to be 0 at the origin for every seed. Without a correction, the center of the island received no coastline or relief variation and stayed the same with any seed.

## Options considered

1. Leave it as it is: no code / the island center ignores the seed.
2. Sample each noise at `(x, z)` plus an offset derived from the seed: the center varies with the seed and generation stays deterministic / two more salts to maintain.

## Decision

Option 2 (architecture 0.2-r4, sections 7.1, 8.2 and 8.3). The coastline and relief noises are sampled with offsets from `UPTGSeed.noise_offset()`, using the new salts `SALT_COASTLINE_OFFSET` (4) and `SALT_TERRAIN_OFFSET` (5). Each offset component is a whole number of meters between 1024 and 9215. Approved by Stefano during Milestone A, 2026-11-06. This ADR was written afterwards, on 2026-11-08, to complete the record started by ADR-0004.

## Consequences

The offset is added in meters, so it does not depend on the grid resolution. `ALGORITHM_VERSION` stayed 1, because the earlier formula was never released.

Source: `UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.md`
