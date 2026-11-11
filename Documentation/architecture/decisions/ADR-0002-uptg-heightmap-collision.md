# ADR-0002: UPTG collision: `HeightMapShape3D` by default

**Status:** Accepted
**Date:** 2026-11-06
**Module:** UPTG

## Context

The terrain needs static collision. Draft 0.1 proposed a concave trimesh, which is the most expensive shape for a regular grid.

## Options considered

1. `ConcavePolygonShape3D` (trimesh) only: exact for any triangulation / more memory and build time.
2. `HeightMapShape3D`: purpose-built for grids, cheaper / fixed triangulation and 1-unit sample spacing.

## Decision

`collision_mode` in `UPTGConfig`: `HEIGHTMAP` (default), `TRIMESH`, `NONE`. Heightmap data are heights divided by `cell_size`, and the `CollisionShape3D` gets a uniform scale of `cell_size`. Decided by Stefano, 2026-11-06.

## Consequences

Milestone 0 results (Godot 4.7.2, Godot Physics and Jolt): the shape is centered on its origin, `map_data` is ordered `iz * width + ix`, every cell is split along the diagonal from vertex `(ix+1, iz)` to `(ix, iz+1)`, and uniform scaling works. Max error against triangle interpolation: 0.19 mm, so the 1 cm tolerance is confirmed. The mesh and `get_height_at()` must use the same diagonal; trimesh faces must be clockwise seen from above when `backface_collision` is off. See `M0_VERIFICATION.md`.

Source: `UPTG/UniversalProceduralTerrainGenerator/documentation/UPTG_ARCHITECTURE_0.2.md`
