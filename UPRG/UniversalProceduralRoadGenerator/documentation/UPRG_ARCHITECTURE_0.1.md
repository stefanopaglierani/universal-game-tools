**English** | [Italiano](UPRG_ARCHITECTURE_0.1.it.md)

# UPRG — Architecture 0.1

**Status:** first version, decided by Stefano's direction of 2026-11-08 (ADR-0009, ADR-0010)
**Target engine:** Godot 4.7.2

## 1. Pipeline

```text
UPTG bake (.scn) ──► UPRG bake (roads, terrain edit) ──► world file (.scn) ──► game
```

`UPRGWorldConfig` describes everything in one `.tres` file, applied in this order: terrain edits, ground of the places, roads, buildings. UPRG reads only the file written by UPTG, format 1 (`terrain_data` metadata, `Mesh`, `Body/Shape`). It contains no UPTG code and never changes its input file.

## 2. Road description

`UPRGRoadConfig` is a `.tres` resource: control points in meters from the terrain center, `width`, `shoulder`, `blend`, `sample_spacing`, `max_grade`, `smoothing`, `sea_clearance`, `sink`, `uv_length`, `road_color`.

## 3. Steps

1. **Path:** Catmull-Rom curve through the points, resampled every `sample_spacing` meters.
2. **Height profile:** terrain height along the path, averaged over `smoothing`, kept `sea_clearance` above the sea, limited to `max_grade` in both directions.
3. **Terrain edit:** vertices within pavement and shoulder go to the road height minus `sink`; over `blend` meters the terrain returns to its own shape. Mesh, normals and height map collision are rebuilt from the edited heights.
4. **Road surface:** one strip with 4 points per cross-section (outer shoulder, two pavement edges, outer shoulder), clockwise seen from above, with a `ConcavePolygonShape3D` made of the same triangles.

## 4. Terrain edits, places and skins

- **`UPRGTerrainEdit`:** a circular area with a soft edge, `ADD` (raise or lower) or `LEVEL` (set a height above the sea).
- **`UPRGPlace`:** levels the ground to its average height, then puts houses on a grid of plots shuffled with the place's own seed. Plots too close to a road are skipped, so fewer buildings than requested can result. All houses of a place are one mesh with one `ConcavePolygonShape3D`, under `Places/Place<n>`.
- **`UPRGSkin`:** images for roads, terrain and buildings, stored inside the file, and tints for terrain and roads.

Places live in UPRG for now because they share its terrain edit and bake step. They can move to UPWG when that module starts.

## 5. Output

The root keeps `terrain_data` with the edited `heights`, a new `heights_checksum`, `source_heights_checksum`, `roads_format_version` (1) and `roads` (path, heights, width and spacing of each road), and `places` (name, center, radius, buildings). Roads are under `Roads/Road<n>`, each with `Body/Shape`. The file has no scripts and no external dependencies.

## 6. Known limits

- The leveled strip beside a road is wider than the road by 1.5 terrain cells, so that its edge stays clean on a coarse grid.
- Buildings are simple boxes with a pitched roof.
- Crossings and junctions are not handled: a later road only edits the terrain under itself.
- Only `HEIGHTMAP` terrain collision is supported.
- The road is drawn where the points say: no automatic route.
