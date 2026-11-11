# ADR-0017: Worlds over 2048 cells per side are exported from their heights, in tiles

**Status:** Accepted
**Date:** 2026-11-11
**Modules:** UPTG, UPRG, UPWG

## Context

Stefano wants worlds of 15 km from the center to the edge (30 km per side), and long export times are acceptable. With UPTG's limit of 2048 cells per side (ADR-0016), 30 km means 15 m cells, too coarse for roads and villages. A finer world cannot be baked as one mesh: at 4 m it has 59 million vertices, several GB as one Godot mesh with its collision.

## Options considered

1. Raise the UPTG grid limit again and bake one mesh: no new code path / runs out of memory well before 30 km at a useful detail.
2. Generate and bake the world piece by piece: lowest memory / lakes and rivers must be planned on the whole world, and every UPRG step would need to work across pieces.
3. Generate only the heights of the whole world at full detail, apply brush strokes and water on them, and write the tiles straight from the heights: about 0.5 GB of heights at the largest size, one place where edits and water are applied / roads and places need this path too before they can be used on large worlds.

## Decision

Option 3.

- UPTG: `UPTGHeightfieldGenerator.generate_heights(config, cell_size)` evaluates the same height function at a finer cell, without mesh or cost check, up to 8192 cells per side. Vertices shared with the normal grid get the same heights.
- UPRG: `UPRGTileBuilder.split_grid()` writes tiles (near and far meshes, collision) and `world.scn` straight from a `UPRGTerrainGrid`; `split()` uses the same tile code.
- UPWG: the project keeps a terrain configuration of at most 2048 cells per side (preview, small exports) and `detail_cell`, the finer cell of the export. When the export has more than 2048 cells per side, the exporter generates the heights, applies the brush strokes and the water, and writes the tiles, the heightmap at full detail and a glTF at the detail of the configuration. The single scene `godot/world.scn` is not written for these worlds; `world.json` says so.

## Consequences

Worlds go up to 30 720 m per side with 4 m cells. Measured on the development PC (2026-11-11): such a world exports in 10.4 min with a 1.8 GB memory peak, writing 4192 tiles (447 MB). Roads and places are not exported yet on large worlds (`world.json` notes it); they must use the same path when the editor gets them. The glTF of a large world is a lighter version; engines should use the heightmap or the Godot tiles for full detail.

Source: `UPWG/UniversalProceduralWorldGenerator/editor/upwg_exporter.gd`
