# ADR-0016: UPTG accepts grids up to 2048 x 2048 cells

**Status:** Accepted
**Date:** 2026-11-11
**Module:** UPTG (used by UPRG and UPWG)

## Context

The UPWG editor must build worlds of about 15 km. With the limit of 1024 cells per side, a 16 km world needs 16 m cells, too coarse for roads and villages. The memory thresholds were set in Milestone D for 1024 x 1024 cells in TRIMESH collision (about 480 MB estimated, under 512 MB).

## Options considered

1. Keep 1024 cells per side: no change / large worlds stay coarse.
2. 2048 cells per side and a 1 GB hard memory limit: 16 km with 8 m cells, 8 km with 4 m cells / a full bake needs more memory and time.
3. No limit, only the memory estimate: largest worlds / a shared preset could still ask for a size that freezes the machine.

## Decision

Option 2. `MAX_CELLS_PER_AXIS` = 2048, `MAX_CELLS_HARD` = 4 194 304 (2048 x 2048), `MAX_BYTES_HARD` = 1 GB. The `OK` thresholds do not change, so anything above 512 x 512 cells still needs `allow_large_terrain` (or the baker's `allow_large` flag).

Measured on the development PC (2026-11-11): a bake of 2048 x 2048 cells takes 44 s, peaks at 785 MB and writes a 58.7 MB file.

## Consequences

UPWG worlds go up to 16 km per side. Large worlds should be exported as tiles (UPRG tiles, UWR reader). Presets made before this change keep working; a grid of 2049 cells per side or more is still refused.

Source: `UPTG/UniversalProceduralTerrainGenerator/addons/uptg/core/uptg_config.gd`
