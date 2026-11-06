**English** | [Italiano](ADR-0006-uptg-cost-protection.it.md)

# ADR-0006: UPTG protection against expensive configurations

**Status:** Accepted
**Date:** 2026-11-06
**Module:** UPTG

## Context

Generation is synchronous GDScript on the main thread. A large grid in a preset, a typo or a runtime change could freeze the game or editor or exhaust memory.

## Options considered

1. Only document limits: no code / no protection.
2. Hard-reject above a size: simple / blocks legitimate large terrains.
3. Pre-generation cost estimate with three levels, large terrains allowed only by an explicit flag on the node: safe by default, still flexible / estimates must be calibrated.

## Decision

Option 3 (architecture §5.4). `UPTGConfig.estimate_cost()` returns cells, vertices, triangles, noise samples and estimated bytes, and a level: `OK`, `LARGE` (refused unless `UPTGTerrain.allow_large_terrain` is true) or `REJECTED` (always refused). The flag lives on the node, so a shared preset cannot bypass it. `TRIMESH` has a lower threshold. `generate()` is not re-entrant. Decided by Stefano, 2026-11-06.

## Consequences

Thresholds are named constants; memory coefficients and time thresholds are estimates to be calibrated with measurements in Milestone D, with approval.

Source: `UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.md`
