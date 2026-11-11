# UPRG — Architecture 0.2

**Status:** describes UPRG 0.1.0 (2026-11-11). It supersedes [architecture 0.1](UPRG_ARCHITECTURE_0.1.md), kept as history.
**Target engine:** Godot 4.7.2

## 1. Pipeline

```text
UPTG bake (.scn) ──► UPRG bake (world.tres) ──► world file (.scn) ──► optional tiles ──► game
```

UPRG reads only the file written by UPTG (format 1, ADR-0010), contains no UPTG code and never changes its input. `UPRGWorldConfig` describes a whole world in one `.tres` file. The bake applies, in this order:

1. terrain edits (`UPRGTerrainEdit`);
2. leveling of the places (`UPRGPlace`);
3. road plans (`UPRGRoadConfig`), rings rotated to start far from everything else;
4. streets planned inside places that ask for them;
5. the junction network (ADR-0011), which fixes the heights where roads meet;
6. one terrain edit for all roads together, then mesh, normals and collision rebuilt;
7. road and junction surfaces, buildings, and the 3D models (`UPRGDressing`);
8. the world file, plus a credits file when models are used.

## 2. Roads

- **Path:** a Catmull-Rom curve through the control points, resampled every `sample_spacing` meters. With `closed` the curve goes back to the first point and the last position repeats the first (ADR-0013).
- **Height profile:** terrain height along the path, averaged over `smoothing`, kept `sea_clearance` above the sea, limited to `max_grade`. Rings average and limit around the closing point.
- **Terrain edit:** within pavement, shoulder and 1.5 cells the terrain goes to the road height minus `sink`, and over `blend` meters it returns to its own shape. Where several roads touch the same vertex, the one that leaves it least of its own shape wins. Where a road bends upward next to a junction, the terrain is lowered further, so that it cannot rise through the pavement.
- **Surface:** 4 points per cross-section, clockwise from above, with a `ConcavePolygonShape3D` made of the same triangles.

## 3. Junctions

Crossings, and roads ending within half a road width of another, become junctions (ADR-0011). The roads meet at one height; the road listed first keeps its own. A junction replaces the road samples around it with one surface with rounded corners, sharing its edge points with the road ends. Next to a junction the slope grows gradually, and only there the profile is rounded. Meetings sharper than 25 degrees and junctions too close on one road are refused with a message. With `UPRGWorldConfig.connected_roads`, a road that cannot be reached through junctions makes the bake fail, naming it.

## 4. Places and streets

`UPRGPlace` levels its ground. Without streets, buildings stand on a shuffled grid of plots away from the roads. With `streets`, a main street joins the nearest road and side streets branch from it; buildings stand along every street, turned toward it. Everything follows the place's own seed.

## 5. Models

`tools/uprg_library.gd` builds a light library from a folder of `.glb`/`.gltf` models and a catalog: one mesh per object, at real size, small textures, and up to six levels of detail generated with `ImporterMesh`. `UPRGDressing` scatters trees, plants, bushes and rocks, puts lamps and props along roads, and builds places from models. Repeated objects are `MultiMesh` groups of `chunk_size` meters with view distances. Each bake writes the credits of the models it used.

## 6. Tiles

`tools/uprg_tiles.gd` cuts a baked world into square tiles (ADR-0012): each tile has a detailed mesh, a light mesh beyond 480 m, skirts against gaps and its own height map collision. Tiles fully under the sea are not written. Roads, places, objects and data stay in `world.scn`. With `--road-colors`, the red vertex color tells how close the ground is to a road, for a game shader that textures the ground itself.

## 7. Output

The root keeps `terrain_data`: the edited `heights` (removed when tiled), checksums, `roads` (path, heights, width, spacing, `street`, `closed`), `junctions` (center, height, radius, roads, arms), `places`, and `tiles` when tiled. The files have no scripts and no external dependencies.

## 8. Known limits

- All junctions are at ground level: no bridges.
- Buildings face their street along +Z; models with another front look sideways.
- The terrain grid is limited by UPTG to 1024 cells per side.
- A game needs its own code to stream tiles and to texture the ground (planned as a separate reader, see the plan of 2026-11-11).
