**English** | [Italiano](ADR-0003-uptg-square-cell-grid.it.md)

# ADR-0003: UPTG grid: square cells defined by cell count and `cell_size`

**Status:** Accepted
**Date:** 2026-11-06
**Module:** UPTG

## Context

Draft 0.1 used independent size and resolution per axis, which allows non-square cells (incompatible with uniform heightmap scaling) and leaves it unclear whether resolution counts vertices or cells.

## Options considered

1. Keep `terrain_size_x/z` + `resolution_x/z`: familiar / non-square cells, off-by-one ambiguity.
2. `grid_cells_x`, `grid_cells_z` and one `cell_size`: always square cells, size is derived / size is not set directly.

## Decision

Option 2. Resolution is the number of cells; vertices are always cells + 1. The terrain is centered on the node origin; vertex `(ix, iz)` is at `((ix - cells_x/2) * cell_size, h, (iz - cells_z/2) * cell_size)` and stored at index `iz * (cells_x + 1) + ix`. Decided by Stefano, 2026-11-06.

## Consequences

Matches `HeightMapShape3D` exactly (verified in Milestone 0). Noise and mask functions sample world coordinates, so changing the cell count changes detail, not island shape. Grid size is bounded by the cost protection (ADR-0006).

Source: `UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.md`
