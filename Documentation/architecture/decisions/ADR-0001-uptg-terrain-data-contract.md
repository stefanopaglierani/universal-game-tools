**English** | [Italiano](ADR-0001-uptg-terrain-data-contract.it.md)

# ADR-0001: UPTG terrain data contract (`UPTGTerrainData`)

**Status:** Accepted
**Date:** 2026-11-06
**Module:** UPTG

## Context

Future modules (roads, vegetation, world generation) need terrain information. Draft 0.1 only said the generator would "return or expose" a result, which would push every consumer into the generator's internals.

## Options considered

1. Expose the generator's internal arrays: no design work now / every internal change breaks consumers.
2. Consumers read the mesh: available already / slow, lossy and tied to rendering.
3. A dedicated read-only data object with documented fields and queries: one stable contract / must be maintained and versioned.

## Decision

Option 3. `UPTGTerrainData` (`RefCounted`) holds heights, land mask, grid size, `cell_size`, sea level and depth, checksums and `ALGORITHM_VERSION`, plus queries such as `get_height_at()`. It is the only interface between UPTG and other systems (architecture §9). Decided by Stefano, 2026-11-06.

## Consequences

Mesh and collision builders take this object as input. Incompatible contract changes need a major version bump and a CHANGELOG entry. Terrain modification by other modules is not covered in v0.1 and needs its own decision.

Source: `UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.md`
