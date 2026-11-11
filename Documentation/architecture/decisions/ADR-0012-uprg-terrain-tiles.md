**English** | [Italiano](ADR-0012-uprg-terrain-tiles.it.md)

# ADR-0012: Very large worlds are cut into terrain tiles after the bake

**Status:** Accepted
**Date:** 2026-11-10
**Module:** UPRG

## Context

A world five times wider than the first island has 2.1 million terrain triangles: too many for a mid-range phone in one piece. Stefano chose one large connected world on 2026-11-09, and its loading had to be proven on his phone first.

## Options considered

1. Generate the terrain directly in tiles inside UPTG: no full mesh / changes UPTG and its data contract.
2. Cut a finished world file into tiles in UPRG: UPTG unchanged, every UPRG feature works as before / the full mesh exists for a moment on the PC.

## Decision

Option 2, with square tiles (64 cells of 5 m in the example world), a light mesh beyond 480 m, skirts against gaps and one height map collision per tile. Everything else stays in `world.scn`. Stefano tested the result on his phone on 2026-11-10 and approved it.

## Consequences

Any baked world can be tiled. The size is still limited by UPTG's 1024 cells per side. A game needs code that streams the tiles; it is not part of UPRG.

Source: `UPRG/UniversalProceduralRoadGenerator/documentation/UPRG_ARCHITECTURE_0.2.md`
